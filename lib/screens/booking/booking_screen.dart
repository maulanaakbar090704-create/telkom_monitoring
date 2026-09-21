import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; 
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:mobile_scanner/mobile_scanner.dart'; 

class BookingScreen extends StatefulWidget {
  final String carName;
  final String plateNumber;

  const BookingScreen({
    super.key,
    required this.carName,
    required this.plateNumber,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color primaryRed = Color(0xFFBB0016);
  static const Color navyBlue = Color(0xFF0F3567);
  static const Color darkText = Color(0xFF0F172A);
  static const Color mutedText = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color softBlue = Color(0xFFEEF4FB);

  late TextEditingController _carNameController;
  late TextEditingController _plateController;

  final TextEditingController _tujuanController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _jamController = TextEditingController();
  final TextEditingController _odoKmController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _scannedFaceBytes;
  bool _isFaceVerifying = false;
  bool _isFaceVerified = false;

  Uint8List? _scannedOdoBytes;

  bool _isSubmitting = false;
  
  String? _scannedQrCode;
  List<Map<String, dynamic>> _availableVehiclesList = [];

  @override
  void initState() {
    super.initState();
    _carNameController = TextEditingController(text: widget.carName);
    _plateController = TextEditingController(text: widget.plateNumber);
    _fetchAvailableVehicles();
  }

  Future<void> _fetchAvailableVehicles() async {
    try {
      final res = await Supabase.instance.client
          .from('vehicles')
          .select('id, registration_no, make_model, pic_name, active')
          .eq('active', true)
          .order('registration_no', ascending: true);
      if (mounted) {
        setState(() {
          _availableVehiclesList = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (_) {}
  }

  void _showVehiclePickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(Icons.directions_car, color: navyBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Plat Nomor Kendaraan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih mobil dinas yang ingin Anda gunakan untuk peminjaman ini',
                  style: TextStyle(fontSize: 13, color: mutedText),
                ),
                const SizedBox(height: 16),
                if (_availableVehiclesList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryRed),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _availableVehiclesList.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final v = _availableVehiclesList[index];
                        final reg = v['registration_no']?.toString() ?? '-';
                        final model = v['make_model']?.toString() ?? 'Toyota Avanza';
                        final pic = v['pic_name']?.toString() ?? 'PIC Kendaraan';
                        final isSelected = reg == _plateController.text.trim();

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: isSelected ? const Color(0xFFFEE2E2) : null,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryRed : softBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: isSelected ? Colors.white : navyBlue,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            reg,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected ? primaryRed : darkText,
                            ),
                          ),
                          subtitle: Text(
                            '$model • PIC: $pic',
                            style: const TextStyle(fontSize: 12, color: mutedText),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: primaryRed, size: 22)
                              : const Icon(Icons.arrow_forward_ios, size: 14, color: mutedText),
                          onTap: () {
                            setState(() {
                              _plateController.text = reg;
                              _carNameController.text = model;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    _carNameController.dispose();
    _plateController.dispose();
    _tujuanController.dispose();
    _lokasiController.dispose();
    _tanggalController.dispose();
    _jamController.dispose();
    _odoKmController.dispose();
    super.dispose();
  }

  Future<FaceVerificationResult> _verifyFace(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 200);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return const FaceVerificationResult(
          isValid: false,
          message: 'Gagal memproses foto wajah. Silakan coba lagi.',
        );
      }

      final width = image.width;
      final height = image.height;
      final totalPixels = width * height;
      final rgba = byteData.buffer.asUint8List();

      int skinPixelsInCenter = 0;
      int centerPixelsCount = 0;
      double totalLuminance = 0;
      final centralRowLuminance = List<double>.filled(height, 0);
      final centralRowCounts = List<int>.filled(height, 0);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = (y * width + x) * 4;
          final r = rgba[idx];
          final g = rgba[idx + 1];
          final b = rgba[idx + 2];

          final yVal = 0.299 * r + 0.587 * g + 0.114 * b;
          totalLuminance += yVal;

          final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
          final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
          final isSkin = (cb >= 75 && cb <= 130) && (cr >= 130 && cr <= 178) && (yVal >= 35 && yVal <= 240);

          final normX = (x - width / 2) / (width * 0.32);
          final normY = (y - height * 0.48) / (height * 0.36);
          final inCenterOval = (normX * normX + normY * normY) <= 1.0;

          if (inCenterOval) {
            centerPixelsCount++;
            if (isSkin) skinPixelsInCenter++;
            centralRowLuminance[y] += yVal;
            centralRowCounts[y]++;
          }
        }
      }

      final avgLuminance = totalLuminance / totalPixels;
      if (avgLuminance < 30) {
        return const FaceVerificationResult(
          isValid: false,
          message: 'Foto terlalu gelap. Gunakan pencahayaan yang cukup agar wajah terlihat jelas.',
        );
      }
      if (avgLuminance > 240) {
        return const FaceVerificationResult(
          isValid: false,
          message: 'Foto terlalu silau. Pastikan wajah tidak tertutup cahaya berlebih.',
        );
      }

      final skinRatioInCenter = centerPixelsCount > 0 ? (skinPixelsInCenter / centerPixelsCount) : 0.0;

      int validRows = 0;
      double rowVarianceSum = 0;
      double lastRowAvg = -1;
      final startY = (height * 0.3).toInt();
      final endY = (height * 0.7).toInt();
      for (int y = startY; y < endY; y++) {
        if (centralRowCounts[y] > 0) {
          final rowAvg = centralRowLuminance[y] / centralRowCounts[y];
          if (lastRowAvg >= 0) {
            rowVarianceSum += (rowAvg - lastRowAvg).abs();
            validRows++;
          }
          lastRowAvg = rowAvg;
        }
      }
      final avgRowVariance = validRows > 0 ? (rowVarianceSum / validRows) : 0.0;

      if (skinRatioInCenter < 0.20) {
        return const FaceVerificationResult(
          isValid: false,
          message: 'Wajah tidak terdeteksi! Pastikan wajah Anda terlihat jelas, menghadap kamera, dan berada di tengah area.',
        );
      }

      if (avgRowVariance < 1.0) {
        return const FaceVerificationResult(
          isValid: false,
          message: 'Objek tidak teridentifikasi sebagai wajah. Arahkan kamera langsung ke wajah Anda.',
        );
      }

      return const FaceVerificationResult(
        isValid: true,
        message: 'Wajah berhasil diverifikasi!',
      );
    } catch (_) {
      return const FaceVerificationResult(
        isValid: true,
        message: 'Wajah berhasil diverifikasi.',
      );
    }
  }

  Future<void> _takeFaceScan() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, 
        imageQuality: 85, 
      );

      if (photo == null) return;

      setState(() {
        _isFaceVerifying = true;
      });

      final bytes = await photo.readAsBytes();
      final result = await _verifyFace(bytes);

      if (!mounted) return;

      setState(() {
        _isFaceVerifying = false;
      });

      if (!result.isValid) {
        setState(() {
          _scannedFaceBytes = null;
          _isFaceVerified = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: primaryRed,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() {
        _scannedFaceBytes = bytes;
        _isFaceVerified = true;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFaceVerifying = false;
        });
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal membuka kamera: $e'), backgroundColor: primaryRed),
        );
      }
    }
  }

  Future<void> _takeOdoScan() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (!mounted) return;
        setState(() {
          _scannedOdoBytes = bytes;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Foto odometer berhasil diambil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto odometer: $e'), backgroundColor: primaryRed),
        );
      }
    }
  }

  Future<String?> _uploadImageToSupabase({
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
      } catch (_) {
        // Coba bucket berikutnya jika belum ada
      }
    }

    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> _takeQrScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _scannedQrCode = result.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Loker berhasil dipindai!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = (_selectedDate != null && !_selectedDate!.isBefore(today))
        ? _selectedDate!
        : today;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today, // Pengisian tanggal tidak boleh di bawah hari ini
      lastDate: DateTime(now.year + 5),
      helpText: 'PILIH TANGGAL PINJAM',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryRed,
              onPrimary: Colors.white,
              onSurface: darkText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: navyBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });

      // Cek apakah jam yang sudah terpilih sebelumnya menjadi invalid (di masa lalu)
      if (_selectedTime != null) {
        final currentNow = DateTime.now();
        final isPickedToday = picked.year == currentNow.year &&
            picked.month == currentNow.month &&
            picked.day == currentNow.day;

        if (isPickedToday) {
          final isPastTime = (_selectedTime!.hour < currentNow.hour) ||
              (_selectedTime!.hour == currentNow.hour && _selectedTime!.minute < currentNow.minute);

          if (isPastTime) {
            setState(() {
              _selectedTime = null;
              _jamController.clear();
            });
            if (mounted) {
              final formattedHour = currentNow.hour.toString().padLeft(2, '0');
              final formattedMin = currentNow.minute.toString().padLeft(2, '0');
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Jam pinjam direset karena lebih awal dari waktu saat ini ($formattedHour:$formattedMin). Silakan pilih jam pinjam kembali.',
                  ),
                  backgroundColor: primaryRed,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_selectedDate == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tanggal pinjam terlebih dahulu.'),
          backgroundColor: primaryRed,
        ),
      );
      await _selectDate(context);
      if (_selectedDate == null) return;
    }

    final now = DateTime.now();
    final isToday = _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    TimeOfDay initialTime = TimeOfDay.now();
    if (_selectedTime != null) {
      if (isToday) {
        final isTimePast = (_selectedTime!.hour < now.hour) ||
            (_selectedTime!.hour == now.hour && _selectedTime!.minute < now.minute);
        initialTime = isTimePast ? TimeOfDay.now() : _selectedTime!;
      } else {
        initialTime = _selectedTime!;
      }
    }

    if (!context.mounted) return;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'PILIH JAM PINJAM',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryRed,
              onPrimary: Colors.white,
              onSurface: darkText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: navyBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final currentNow = DateTime.now();
      final isPickedToday = _selectedDate!.year == currentNow.year &&
          _selectedDate!.month == currentNow.month &&
          _selectedDate!.day == currentNow.day;

      if (isPickedToday) {
        final isPast = (picked.hour < currentNow.hour) ||
            (picked.hour == currentNow.hour && picked.minute < currentNow.minute);

        if (isPast) {
          final currentHourStr = currentNow.hour.toString().padLeft(2, '0');
          final currentMinStr = currentNow.minute.toString().padLeft(2, '0');
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Jam pinjam tidak boleh di bawah jam saat ini ($currentHourStr:$currentMinStr).'),
                backgroundColor: primaryRed,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _selectedTime = picked;
        _jamController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  DateTime? _parseInputDateTime(String dateStr, String timeStr) {
    try {
      int day = 0, month = 0, year = 0;
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          day = int.parse(parts[0]);
          month = int.parse(parts[1]);
          year = int.parse(parts[2]);
        }
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            year = int.parse(parts[0]);
            month = int.parse(parts[1]);
            day = int.parse(parts[2]);
          } else {
            day = int.parse(parts[0]);
            month = int.parse(parts[1]);
            year = int.parse(parts[2]);
          }
        }
      }

      int hour = 0, minute = 0;
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      } else if (timeStr.contains('.')) {
        final parts = timeStr.split('.');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      }

      if (year > 0 && month > 0 && day > 0) {
        return DateTime(year, month, day, hour, minute);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: const [
            Icon(Icons.directions_car, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Booking Flow', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryRed, navyBlue],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Peminjaman kendaraan', style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('Lengkapi detail perjalanan untuk melanjutkan peminjaman.', style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                      const SizedBox(height: 20),
                      _buildVehicleCard(),
                      const SizedBox(height: 16),
                      _buildScheduleCard(),
                      const SizedBox(height: 16),
                      _buildOdometerCard(),
                      const SizedBox(height: 16),
                      _buildFaceVerificationCard(), 
                      const SizedBox(height: 16),
                      _buildQrVerificationCard(),
                      
                      const SizedBox(height: 32),
                      _buildConfirmButton(),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Dengan melanjutkan, Anda menyetujui kebijakan peminjaman kendaraan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard() {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(icon: Icons.directions_car_outlined, title: 'Detail kendaraan'),
          const SizedBox(height: 16),
          _buildInputField(label: 'Nama Kendaraan', icon: Icons.directions_car_outlined, controller: _carNameController, readOnly: true),
          const SizedBox(height: 14),
          _buildInputField(
            label: 'Plat Nomor',
            icon: Icons.local_offer_outlined,
            controller: _plateController,
            hint: 'Pilih plat nomor...',
            readOnly: true,
            onTap: _showVehiclePickerModal,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(icon: Icons.calendar_month_outlined, title: 'Jadwal peminjaman'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Tanggal Pinjam',
                  icon: Icons.calendar_today_outlined,
                  controller: _tanggalController,
                  hint: 'DD/MM/YYYY',
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: 'Jam Pinjam',
                  icon: Icons.access_time_outlined,
                  controller: _jamController,
                  hint: '08:00',
                  readOnly: true,
                  onTap: () => _selectTime(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInputField(label: 'Tujuan Peminjaman', icon: Icons.work_outline, controller: _tujuanController, hint: 'Contoh: Kunjungan klien'),
          const SizedBox(height: 14),
          _buildInputField(label: 'Lokasi / Destinasi', icon: Icons.location_on_outlined, controller: _lokasiController, hint: 'Contoh: Gedung Telkom'),
        ],
      ),
    );
  }

  Widget _buildOdometerCard() {
    final bool hasOdo = _scannedOdoBytes != null;

    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_outlined, color: navyBlue, size: 22),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foto Odometer & KM Kendaraan', style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Wajib catat KM awal & lampirkan foto speedometer', style: TextStyle(color: mutedText, fontSize: 12)),
                  ],
                ),
              ),
              if (hasOdo && _odoKmController.text.trim().isNotEmpty)
                const Icon(Icons.check_circle, color: Colors.green, size: 23),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Angka KM Odometer Saat Ini',
            icon: Icons.pin_outlined,
            controller: _odoKmController,
            hint: 'Contoh: 45200',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: hasOdo ? const Color(0xFFECFDF5) : softBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: hasOdo ? const Color(0xFFA7F3D0) : const Color(0xFFD5E2F0)),
            ),
            child: hasOdo
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _scannedOdoBytes!,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 10,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Foto Odometer Terlampir',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: navyBlue.withValues(alpha: 0.7), size: 48),
                      const SizedBox(height: 10),
                      const Text(
                        'Ambil foto panel odometer / speedometer',
                        style: TextStyle(color: darkText, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pastikan angka KM terbaca dengan jelas',
                        style: TextStyle(color: mutedText, fontSize: 11),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _takeOdoScan,
              icon: Icon(hasOdo ? Icons.refresh : Icons.camera_alt_outlined),
              label: Text(
                hasOdo ? 'Foto Ulang Odometer' : 'Ambil Foto Odometer',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasOdo ? Colors.green.shade700 : navyBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceVerificationCard() {
    final bool hasFace = _scannedFaceBytes != null && _isFaceVerified;

    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.face_retouching_natural_outlined, color: navyBlue, size: 22),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verifikasi Wajah', style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Pastikan wajah terlihat jelas di kamera', style: TextStyle(color: mutedText, fontSize: 12)),
                  ],
                ),
              ),
              if (hasFace) const Icon(Icons.check_circle, color: Colors.green, size: 23),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: hasFace ? const Color(0xFFECFDF5) : softBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: hasFace ? const Color(0xFFA7F3D0) : const Color(0xFFD5E2F0)),
            ),
            child: _isFaceVerifying
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: navyBlue),
                      SizedBox(height: 14),
                      Text(
                        'Memverifikasi deteksi wajah...',
                        style: TextStyle(color: darkText, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Memeriksa pencahayaan dan kontur wajah',
                        style: TextStyle(color: mutedText, fontSize: 11),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      hasFace
                          ? Center(
                              child: Container(
                                width: 142,
                                height: 142,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.8), width: 3),
                                  image: DecorationImage(
                                    image: MemoryImage(_scannedFaceBytes!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 116,
                                  height: 142,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: navyBlue.withValues(alpha: 0.55), width: 3),
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                ),
                              ],
                            ),
                      if (!hasFace) const Icon(Icons.person_outline, color: navyBlue, size: 70),
                      if (!hasFace)
                        const Positioned(
                          bottom: 28,
                          child: Text(
                            'Posisikan wajah di dalam area',
                            style: TextStyle(color: darkText, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Positioned(
                        bottom: 10,
                        child: Text(
                          hasFace ? 'Wajah Terverifikasi Valid' : 'Gunakan pencahayaan yang cukup',
                          style: TextStyle(
                            color: hasFace ? Colors.green[700] : mutedText,
                            fontSize: 11,
                            fontWeight: hasFace ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isFaceVerifying ? null : _takeFaceScan,
              icon: Icon(hasFace ? Icons.refresh : Icons.camera_alt_outlined),
              label: Text(
                hasFace ? 'Scan Ulang Wajah' : 'Scan Wajah',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasFace ? Colors.green.shade700 : navyBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrVerificationCard() {
    bool hasQr = _scannedQrCode != null; 

    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_scanner, color: navyBlue, size: 22),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Akses Smart Locker', style: TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Scan kode QR pada pintu loker kunci', style: TextStyle(color: mutedText, fontSize: 12)),
                  ],
                ),
              ),
              if (hasQr) const Icon(Icons.check_circle, color: Colors.green, size: 23),
            ],
          ),
          const SizedBox(height: 14),
          if (hasQr) 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.only(bottom:12),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFA7F3D0))),
              child: Column(
                children: [
                  const Text('Kode Loker Tersimpan:', style: TextStyle(color: Color(0xFF065F46), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(_scannedQrCode!, style: const TextStyle(color: Color(0xFF047857), fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _takeQrScan, 
              icon: Icon(hasQr ? Icons.refresh : Icons.qr_code_2),
              label: Text(hasQr ? 'Scan Ulang QR Loker' : 'Scan QR Loker', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasQr ? Colors.green.shade700 : navyBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _confirmBooking,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.arrow_forward),
        label: Text(
          _isSubmitting ? 'Memproses Peminjaman...' : 'Konfirmasi Pinjaman',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: navyBlue, size: 22),
        const SizedBox(width: 9),
        Text(title, style: const TextStyle(color: darkText, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String hint = '',
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    final bool isInteractive = onTap != null;
    final bool isDisabled = readOnly && !isInteractive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: darkText, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          style: TextStyle(color: isDisabled ? mutedText : darkText, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(icon, color: navyBlue, size: 20),
            suffixIcon: isInteractive ? const Icon(Icons.arrow_drop_down, color: navyBlue) : null,
            filled: true,
            fillColor: isDisabled ? const Color(0xFFF1F5F9) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: navyBlue, width: 2)),
          ),
        ),
      ],
    );
  }

  void _confirmBooking() {
    final isFormIncomplete =
        _tanggalController.text.trim().isEmpty ||
        _jamController.text.trim().isEmpty ||
        _tujuanController.text.trim().isEmpty ||
        _lokasiController.text.trim().isEmpty ||
        _odoKmController.text.trim().isEmpty ||
        _scannedOdoBytes == null ||
        _scannedFaceBytes == null ||
        !_isFaceVerified ||
        _scannedQrCode == null;

    if (isFormIncomplete) {
      String errorMessage = 'Lengkapi seluruh data peminjaman.';
      if (_odoKmController.text.trim().isEmpty) {
        errorMessage = 'Harap isi angka KM odometer kendaraan!';
      } else if (_scannedOdoBytes == null) {
        errorMessage = 'Harap ambil foto odometer / speedometer kendaraan!';
      } else if (_scannedFaceBytes == null || !_isFaceVerified) {
        errorMessage = 'Harap lakukan verifikasi wajah sampai berhasil!';
      } else if (_scannedQrCode == null) {
        errorMessage = 'Harap scan QR loker kunci!';
      } else {
        errorMessage = 'Lengkapi formulir jadwal, tujuan, dan lokasi peminjaman!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: primaryRed,
        ),
      );
      return;
    }

    final now = DateTime.now();
    DateTime? scheduledDateTime;

    if (_selectedDate != null && _selectedTime != null) {
      scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    } else {
      scheduledDateTime = _parseInputDateTime(_tanggalController.text.trim(), _jamController.text.trim());
    }

    if (scheduledDateTime != null && scheduledDateTime.isBefore(now)) {
      final currentHour = now.hour.toString().padLeft(2, '0');
      final currentMin = now.minute.toString().padLeft(2, '0');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tanggal dan jam peminjaman tidak boleh sebelum waktu saat ini ($currentHour:$currentMin)!'),
          backgroundColor: primaryRed,
        ),
      );
      return;
    }

    _showPolicyDialog(context);
  }

  void _showPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.gavel_rounded, color: navyBlue, size: 24),
              SizedBox(width: 10),
              Text('Kebijakan Peminjaman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sebelum melanjutkan peminjaman kendaraan operasional Telkom, harap perhatikan ketentuan berikut:', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4)),
                SizedBox(height: 12),
                Text(
                  '1. Kendaraan wajib dikembalikan tepat waktu.\n\n'
                  '2. Kebersihan menjadi tanggung jawab peminjam.\n\n'
                  '3. Pelanggaran lalu lintas ditanggung peminjam.\n\n'
                  '4. Dilarang merokok di dalam kendaraan.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); 
                _submitBookingToSupabase(); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: navyBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Setuju & Ajukan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitBookingToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User tidak ditemukan.'), backgroundColor: primaryRed));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Tampilkan loading dialog selama proses unggah & simpan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: navyBlue),
                SizedBox(height: 16),
                Text(
                  'Mengunggah foto & menyimpan data...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkText),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final currentPlate = _plateController.text.trim().isNotEmpty
          ? _plateController.text.trim()
          : widget.plateNumber.trim();

      dynamic vehicleRes;
      try {
        vehicleRes = await Supabase.instance.client
            .from('vehicles')
            .select('id, pic_name')
            .eq('registration_no', currentPlate)
            .single();
      } catch (_) {
        vehicleRes = await Supabase.instance.client
            .from('vehicles')
            .select('id, pic_name')
            .eq('registration_no', widget.plateNumber)
            .single();
      }
          
      final vehicleId = vehicleRes['id'];
      final picName = vehicleRes['pic_name']?.toString() ?? 'PIC Kendaraan';

      DateTime? bookingDateTime;
      if (_selectedDate != null && _selectedTime != null) {
        bookingDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      } else {
        bookingDateTime = _parseInputDateTime(_tanggalController.text.trim(), _jamController.text.trim());
      }
      final startAtTime = (bookingDateTime ?? DateTime.now()).toIso8601String();

      // 1. Unggah foto wajah ke Supabase Storage
      String? facePhotoUrl;
      if (_scannedFaceBytes != null) {
        facePhotoUrl = await _uploadImageToSupabase(
          bytes: _scannedFaceBytes!,
          prefix: 'face',
          userId: user.id,
        );
      }

      // 2. Unggah foto odometer ke Supabase Storage
      String? odoPhotoUrl;
      if (_scannedOdoBytes != null) {
        odoPhotoUrl = await _uploadImageToSupabase(
          bytes: _scannedOdoBytes!,
          prefix: 'odo',
          userId: user.id,
        );
      }

      final kmText = _odoKmController.text.trim();
      final adminNoteContent = '[KM Awal: $kmText km | Foto Odo: ${odoPhotoUrl ?? "-"}]';

      final Map<String, dynamic> bookingData = {
        'employee_id': user.id,
        'vehicle_id': vehicleId,
        'plat_nomor': currentPlate,
        'purpose': _tujuanController.text.trim(),
        'destination': _lokasiController.text.trim(),
        'start_at': startAtTime,
        'status': 'pending_admin', // Status awal: Menunggu persetujuan PIC/Pemilik mobil
        'qr_locker_code': _scannedQrCode,
        'face_photo_path': facePhotoUrl,
        'admin_note': adminNoteContent,
      };

      // Coba masukkan dengan kolom tambahan jika user telah menambahkan odo_photo_path dan start_odometer
      try {
        final extendedData = Map<String, dynamic>.from(bookingData);
        final kmNum = num.tryParse(kmText);
        if (kmNum != null) extendedData['start_odometer'] = kmNum;
        if (odoPhotoUrl != null) extendedData['odo_photo_path'] = odoPhotoUrl;
        await Supabase.instance.client.from('bookings').insert(extendedData);
      } catch (_) {
        // Fallback jika kolom start_odometer / odo_photo_path belum ada di tabel bookings Supabase
        try {
          await Supabase.instance.client.from('bookings').insert(bookingData);
        } catch (_) {
          final fallbackData = Map<String, dynamic>.from(bookingData)..remove('plat_nomor');
          await Supabase.instance.client.from('bookings').insert(fallbackData);
        }
      }

      if (!mounted) return;
      // Tutup loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        _isSubmitting = false;
      });

      _showSuccessDialog(context, picName);
    } catch (e) {
      if (!mounted) return;
      // Tutup loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan: $e'), backgroundColor: primaryRed),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, String picName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 42),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Permohonan Terkirim!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'MENUNGGU PERSETUJUAN PEMILIK MOBIL',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pengajuan peminjaman mobil Anda telah dikirimkan ke PIC/Pemilik kendaraan ($picName).\n\nSetelah disetujui (di-ACC), smart locker akan terbuka secara otomatis dan status kendaraan akan aktif untuk digunakan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.45),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyBlue,
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
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanned = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Loker Kunci', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF0F3567),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isScanned) return; 

          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              setState(() {
                _isScanned = true; 
              });
              
              Navigator.pop(context, barcode.rawValue);
              break; 
            }
          }
        },
      ),
    );
  }
}

class FaceVerificationResult {
  final bool isValid;
  final String message;

  const FaceVerificationResult({
    required this.isValid,
    required this.message,
  });
}