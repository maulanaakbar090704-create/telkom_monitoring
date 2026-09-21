import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../booking/booking_screen.dart';

class ReturnScreen extends StatefulWidget {
  final String? bookingId;
  final Map<String, dynamic>? initialBooking;

  const ReturnScreen({
    super.key,
    this.bookingId,
    this.initialBooking,
  });

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  static const Color darkNavy = Color(0xFF1B1A30);
  static const Color primaryRed = Color(0xFFBB0016);
  
  Map<String, dynamic>? activeBooking;
  bool isLoading = true;
  bool _isSubmitting = false;

  // Controller untuk Kamera & Gambar
  final ImagePicker _picker = ImagePicker();
  
  // Status penyimpanan file & bytes foto kendaraan (4 sisi)
  XFile? fotoDepan;
  XFile? fotoKanan;
  XFile? fotoKiri;
  XFile? fotoBelakang;

  Uint8List? bytesDepan;
  Uint8List? bytesKanan;
  Uint8List? bytesKiri;
  Uint8List? bytesBelakang;

  // Foto Odometer & KM Akhir
  XFile? fotoOdo;
  Uint8List? bytesOdo;
  final TextEditingController _kmAkhirController = TextEditingController();

  // Scan QR Loker Kunci Pengembalian
  String? _scannedReturnQrCode;

  @override
  void initState() {
    super.initState();
    if (widget.initialBooking != null) {
      activeBooking = widget.initialBooking;
      isLoading = false;
    }
    _fetchActiveBooking();
  }

  @override
  void dispose() {
    _kmAkhirController.dispose();
    super.dispose();
  }

  // Tarik data mobil yang sedang dipinjam
  Future<void> _fetchActiveBooking() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      var query = Supabase.instance.client
          .from('bookings')
          .select('*, vehicles(make_model, registration_no)');

      if (widget.bookingId != null) {
        query = query.eq('id', widget.bookingId!);
      } else {
        query = query.eq('employee_id', user.id).eq('status', 'active');
      }

      final response = await query.order('created_at', ascending: false).limit(1);

      if (mounted) {
        setState(() {
          if (response.isNotEmpty) {
            activeBooking = response.first;
          } else if (widget.initialBooking == null) {
            activeBooking = null;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat booking aktif: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String? _getInitialKm() {
    if (activeBooking == null) return null;
    if (activeBooking!['start_odometer'] != null) {
      return activeBooking!['start_odometer'].toString();
    }
    final vehicleOdo = activeBooking!['vehicles']?['odometer'];
    if (vehicleOdo != null) {
      return vehicleOdo.toString();
    }
    final adminNote = activeBooking!['admin_note']?.toString() ?? '';
    final match = RegExp(r'KM Awal:\s*(\d+)').firstMatch(adminNote);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  // Fungsi untuk membuka kamera langsung dan menyimpan hasil fotonya
  Future<void> _takePhoto(String posisi) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          if (posisi == 'depan') {
            fotoDepan = photo;
            bytesDepan = bytes;
          } else if (posisi == 'kanan') {
            fotoKanan = photo;
            bytesKanan = bytes;
          } else if (posisi == 'kiri') {
            fotoKiri = photo;
            bytesKiri = bytes;
          } else if (posisi == 'belakang') {
            fotoBelakang = photo;
            bytesBelakang = bytes;
          } else if (posisi == 'odo') {
            fotoOdo = photo;
            bytesOdo = bytes;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e'), backgroundColor: primaryRed),
        );
      }
    }
  }

  // Dialog perbesar / tinjau foto yang sudah ada
  void _showImagePreviewDialog(String title, Uint8List bytes, String posisi) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    bytes,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _takePhoto(posisi);
                        },
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Foto Ulang (Kamera)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryRed,
                          side: const BorderSide(color: primaryRed),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Scan QR Smart Locker
  Future<void> _takeQrScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _scannedReturnQrCode = result.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR Loker berhasil dipindai: $_scannedReturnQrCode'), backgroundColor: Colors.green),
      );
    }
  }

  // Dialog manual / simulasi loker untuk kemudahan pengetesan di browser
  void _showManualLockerDialog() {
    final textCtrl = TextEditingController(text: _scannedReturnQrCode ?? '');
    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.dialpad_outlined, color: Color(0xFF0F3567)),
              SizedBox(width: 8),
              Text('Kode Smart Locker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Masukkan nomor atau kode loker kunci pengembalian:', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                decoration: InputDecoration(
                  hintText: 'Contoh: LOKER-B01',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['LOKER-A01', 'LOKER-B02', 'LOKER-C03'].map((sample) {
                  return ActionChip(
                    label: Text(sample, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      textCtrl.text = sample;
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = textCtrl.text.trim();
                if (val.isNotEmpty) {
                  setState(() {
                    _scannedReturnQrCode = val;
                  });
                  Navigator.pop(dlgContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kode loker ditetapkan: $val'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3567),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Upload gambar ke Supabase Storage
  Future<String?> _uploadImageBytes({
    required Uint8List bytes,
    required String prefix,
    required String userId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${userId}_${prefix}_$timestamp.jpg';

    final candidateBuckets = ['bookings', 'photos', 'avatars', 'vehicles'];
    for (final bucket in candidateBuckets) {
      try {
        await Supabase.instance.client.storage.from(bucket).uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        return Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);
      } catch (_) {}
    }

    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  // Fungsi Submit Pengembalian Mobil
  Future<void> _submitReturn() async {
    // 1. Validasi Foto Kendaraan (4 sisi)
    if (bytesDepan == null || bytesKanan == null || bytesKiri == null || bytesBelakang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi ke-4 foto kendaraan (Depan, Kanan, Kiri, Belakang)!'),
          backgroundColor: primaryRed,
        ),
      );
      return;
    }

    // 2. Validasi KM Akhir
    final kmText = _kmAkhirController.text.trim();
    if (kmText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan angka KM odometer akhir kendaraan!'),
          backgroundColor: primaryRed,
        ),
      );
      return;
    }

    // 3. Validasi Foto Odometer
    if (bytesOdo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap ambil foto odometer akhir kendaraan!'),
          backgroundColor: primaryRed,
        ),
      );
      return;
    }

    // 4. Validasi Scan QR Loker
    if (_scannedReturnQrCode == null || _scannedReturnQrCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap scan QR loker untuk membuka loker pengembalian kunci!'),
          backgroundColor: primaryRed,
        ),
      );
      return;
    }

    if (activeBooking == null) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? 'user';
      final bookingId = activeBooking!['id'];
      final vehicleId = activeBooking!['vehicle_id'];

      // Upload foto odo akhir
      String? returnOdoUrl;
      if (bytesOdo != null) {
        returnOdoUrl = await _uploadImageBytes(
          bytes: bytesOdo!,
          prefix: 'return_odo',
          userId: userId,
        );
      }

      final existingNote = activeBooking!['admin_note']?.toString() ?? '';
      final returnNote = '[KM Akhir: $kmText km | Foto Return Odo: ${returnOdoUrl ?? "-"} | Loker Return: $_scannedReturnQrCode]';
      final updatedAdminNote = existingNote.isEmpty ? returnNote : '$existingNote\n$returnNote';

      final Map<String, dynamic> updateData = {
        'status': 'completed',
        'returned_at': DateTime.now().toIso8601String(),
        'admin_note': updatedAdminNote,
      };

      final kmNum = num.tryParse(kmText);
      if (kmNum != null) {
        try {
          final extendedUpdate = Map<String, dynamic>.from(updateData);
          extendedUpdate['end_odometer'] = kmNum;
          if (returnOdoUrl != null) extendedUpdate['return_odo_photo'] = returnOdoUrl;
          if (_scannedReturnQrCode != null) extendedUpdate['return_qr_locker_code'] = _scannedReturnQrCode;
          await Supabase.instance.client.from('bookings').update(extendedUpdate).eq('id', bookingId);
        } catch (_) {
          await Supabase.instance.client.from('bookings').update(updateData).eq('id', bookingId);
        }
      } else {
        await Supabase.instance.client.from('bookings').update(updateData).eq('id', bookingId);
      }

      // Update status ketersediaan kendaraan (active = true)
      if (vehicleId != null) {
        try {
          await Supabase.instance.client
              .from('vehicles')
              .update({'active': true})
              .eq('id', vehicleId);
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengembalikan mobil: $e'), backgroundColor: primaryRed),
        );
      }
    }
  }

  // POPUP SUKSES MENGEMBALIKAN MOBIL
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76, height: 76,
                  decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
                ),
                const SizedBox(height: 20),
                const Text('Pengembalian Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 8),
                Text(
                  'Kunci telah dikembalikan ke loker ${_scannedReturnQrCode ?? "-"}.\nLoker telah terkunci dan status kendaraan telah diperbarui menjadi selesai.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Kembali ke Beranda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Format jam
  String _formatTime(String rawDate) {
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      return "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return rawDate.split(' ').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : activeBooking == null
              ? const Center(
                  child: Text('Tidak ada kendaraan yang sedang dipinjam.', style: TextStyle(color: Colors.white)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildVehicleDetailCard(),
                      const SizedBox(height: 16),
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildPhotoCard(),
                      const SizedBox(height: 16),
                      _buildOdometerCard(),
                      const SizedBox(height: 16),
                      _buildQrLockerCard(),
                      const SizedBox(height: 24),
                      _buildBottomSubmitButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  // --- CARD 1: DETAIL KENDARAAN ---
  Widget _buildVehicleDetailCard() {
    final vehicle = activeBooking!['vehicles'] ?? {};
    final carName = vehicle['make_model'] ?? 'Mobil Kantor';
    final plateNumber = vehicle['registration_no'] ?? activeBooking!['plat_nomor'] ?? '-';
    
    final rawStartAt = activeBooking!['start_at'] ?? 'Hari ini';
    final formattedTime = _formatTime(rawStartAt.toString());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plateNumber,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 12, color: primaryRed),
                    SizedBox(width: 4),
                    Text('IN USE', style: TextStyle(color: primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(child: _buildInfoColumn(Icons.calendar_today_outlined, 'Date', 'Today')),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoColumn(Icons.access_time_outlined, 'Pickup Time', formattedTime)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildInfoColumn(Icons.location_on_outlined, 'Pickup Loc', 'HQ Parking B1')),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoColumn(Icons.local_gas_station_outlined, 'Initial Fuel', 'Full')),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD 2: STATUS CEKLIS ---
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vehicle Status', style: TextStyle(fontSize: 14, color: Colors.black54)),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: primaryRed, size: 20),
              SizedBox(width: 8),
              Text('Pre-trip inspection passed', style: TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: primaryRed, size: 20),
              SizedBox(width: 8),
              Text('Key retrieved from locker', style: TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD 3: FOTO KENDARAAN (DENGAN PRATINJAU FOTO LANGSUNG) ---
  Widget _buildPhotoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Foto Kendaraan (4 Sisi)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(
                '${[bytesDepan, bytesKanan, bytesKiri, bytesBelakang].where((e) => e != null).length}/4 Lengkap',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryRed),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Ketuk kotak untuk mengambil atau melihat foto kendaraan', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPhotoBox('Tampilan Depan', 'depan', bytesDepan)),
              const SizedBox(width: 12),
              Expanded(child: _buildPhotoBox('Samping Kanan', 'kanan', bytesKanan)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPhotoBox('Samping Kiri', 'kiri', bytesKiri)),
              const SizedBox(width: 12),
              Expanded(child: _buildPhotoBox('Tampilan Belakang', 'belakang', bytesBelakang)),
            ],
          ),
        ],
      ),
    );
  }

  // Kotak Foto dengan Pratinjau Gambar Langsung
  Widget _buildPhotoBox(String title, String posisi, Uint8List? bytes) {
    final bool isFilled = bytes != null;
    return GestureDetector(
      onTap: () {
        if (isFilled) {
          _showImagePreviewDialog(title, bytes, posisi);
        } else {
          _takePhoto(posisi);
        }
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: isFilled ? Colors.white : const Color(0xFFF9FAFB),
          border: Border.all(
            color: isFilled ? primaryRed : const Color(0xFFE5E7EB),
            width: isFilled ? 1.5 : 1.2,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isFilled
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 3))]
              : null,
        ),
        child: isFilled
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12.5),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.touch_app_outlined, color: Colors.white70, size: 13),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: primaryRed, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ketuk untuk foto',
                    style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
      ),
    );
  }

  // --- CARD 4: FOTO ODOMETER & KM AKHIR ---
  Widget _buildOdometerCard() {
    final initialKm = _getInitialKm();
    final bool hasOdoPhoto = bytesOdo != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                child: const Icon(Icons.speed_rounded, color: primaryRed, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foto Odometer & KM Akhir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    SizedBox(height: 2),
                    Text('Catat kilometer akhir dan foto speedometer', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              if (hasOdoPhoto && _kmAkhirController.text.trim().isNotEmpty)
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
            ],
          ),
          const SizedBox(height: 16),

          if (initialKm != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'KM Awal Pinjam: $initialKm km',
                    style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],

          const Text('Angka KM Odometer Akhir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          TextField(
            controller: _kmAkhirController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Masukkan angka KM saat ini (cth: 45200)',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.pin_outlined, color: primaryRed, size: 20),
              suffixText: 'KM',
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryRed, width: 1.8)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Foto Speedometer / Odometer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: () {
              if (hasOdoPhoto) {
                _showImagePreviewDialog('Foto Odometer Akhir', bytesOdo!, 'odo');
              } else {
                _takePhoto('odo');
              }
            },
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: hasOdoPhoto ? Colors.white : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasOdoPhoto ? primaryRed : const Color(0xFFD1D5DB),
                  width: hasOdoPhoto ? 1.5 : 1.2,
                ),
              ),
              child: hasOdoPhoto
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            bytesOdo!,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.85),
                                    Colors.black.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Foto Odometer Terlampir (Ketuk untuk ubah/lihat)',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                              child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_outlined, color: primaryRed, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text('Ambil Foto Odometer / Speedometer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                        const SizedBox(height: 4),
                        const Text('Pastikan angka kilometer terlihat jelas', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CARD 5: SCAN QR SMART LOCKER ---
  Widget _buildQrLockerCard() {
    final bool hasQr = _scannedReturnQrCode != null && _scannedReturnQrCode!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0F3567), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Akses Smart Locker (Kembalikan Kunci)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    SizedBox(height: 2),
                    Text('Scan kode QR pada loker untuk mengembalikan kunci', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              if (hasQr) const Icon(Icons.check_circle, color: Colors.green, size: 22),
            ],
          ),
          const SizedBox(height: 16),

          if (hasQr) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_open_rounded, color: Color(0xFF047857), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pintu Loker Terbuka', style: TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Kode Loker: $_scannedReturnQrCode', style: const TextStyle(color: Color(0xFF047857), fontSize: 12)),
                        const SizedBox(height: 2),
                        const Text('Silakan masukkan kunci kendaraan ke dalam loker.', style: TextStyle(color: Color(0xFF047857), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _takeQrScan,
                    icon: Icon(hasQr ? Icons.refresh : Icons.qr_code_scanner, size: 18),
                    label: Text(
                      hasQr ? 'Scan Ulang QR' : 'Scan QR Loker Kunci',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasQr ? Colors.green.shade700 : const Color(0xFF0F3567),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _showManualLockerDialog,
                    icon: const Icon(Icons.keyboard_outlined, size: 16),
                    label: const Text(
                      'Manual',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- BUTTON: SUBMIT AKHIR DI PALING BAWAH ---
  Widget _buildBottomSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitReturn,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.vpn_key_outlined, color: Colors.white, size: 20),
        label: Text(
          _isSubmitting ? 'Memproses Pengembalian...' : 'Selesai & Kembalikan Kunci',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}