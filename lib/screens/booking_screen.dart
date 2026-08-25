import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'history_screen.dart';

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

  bool _faceVerified = false;

  @override
  void initState() {
    super.initState();
    _carNameController = TextEditingController(text: widget.carName);
    _plateController = TextEditingController(text: widget.plateNumber);
  }

  @override
  void dispose() {
    _carNameController.dispose();
    _plateController.dispose();
    _tujuanController.dispose();
    _lokasiController.dispose();
    _tanggalController.dispose();
    _jamController.dispose();
    super.dispose();
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
            Text(
              'Booking Flow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
              const SizedBox(height: 64),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Peminjaman kendaraan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lengkapi detail perjalanan untuk melanjutkan peminjaman.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildUserCard(),
                      const SizedBox(height: 16),
                      _buildVehicleCard(),
                      const SizedBox(height: 16),
                      _buildScheduleCard(),
                      const SizedBox(height: 16),
                      _buildFaceVerificationCard(),
                      const SizedBox(height: 20),
                      _buildConfirmButton(),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Dengan melanjutkan, Anda menyetujui kebijakan peminjaman kendaraan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.5,
                          ),
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

  Widget _buildUserCard() {
    return _buildWhiteCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: navyBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maulana Akbar',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ID Karyawan: TEL-2026-001',
                  style: TextStyle(color: mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.directions_car_outlined,
            title: 'Detail kendaraan',
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Nama Kendaraan',
            icon: Icons.directions_car_outlined,
            controller: _carNameController,
            readOnly: true,
          ),
          const SizedBox(height: 14),
          _buildInputField(
            label: 'Plat Nomor',
            icon: Icons.local_offer_outlined,
            controller: _plateController,
            readOnly: true,
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
          _buildSectionTitle(
            icon: Icons.calendar_month_outlined,
            title: 'Jadwal peminjaman',
          ),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: 'Jam Pinjam',
                  icon: Icons.access_time_outlined,
                  controller: _jamController,
                  hint: '08:00',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInputField(
            label: 'Tujuan Peminjaman',
            icon: Icons.work_outline,
            controller: _tujuanController,
            hint: 'Contoh: Kunjungan klien',
          ),
          const SizedBox(height: 14),
          _buildInputField(
            label: 'Lokasi / Destinasi',
            icon: Icons.location_on_outlined,
            controller: _lokasiController,
            hint: 'Contoh: Gedung Telkom',
          ),
        ],
      ),
    );
  }

  Widget _buildFaceVerificationCard() {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.face_retouching_natural_outlined,
                color: navyBlue,
                size: 22,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi wajah',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pastikan wajah terlihat jelas',
                      style: TextStyle(color: mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_faceVerified)
                const Icon(Icons.check_circle, color: Colors.green, size: 23),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              color: _faceVerified ? const Color(0xFFECFDF5) : softBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _faceVerified
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFD5E2F0),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildCameraGuide(),
                Icon(
                  _faceVerified
                      ? Icons.check_circle_outline
                      : Icons.person_outline,
                  color: _faceVerified ? Colors.green : navyBlue,
                  size: 70,
                ),
                Positioned(
                  bottom: 28,
                  child: Text(
                    _faceVerified
                        ? 'Wajah berhasil diverifikasi'
                        : 'Posisikan wajah di dalam area',
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  child: Text(
                    _faceVerified
                        ? 'Preview tersimpan di perangkat'
                        : 'Gunakan pencahayaan yang cukup',
                    style: const TextStyle(color: mutedText, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _scanFace,
              icon: Icon(
                _faceVerified ? Icons.refresh : Icons.camera_alt_outlined,
              ),
              label: Text(
                _faceVerified ? 'Scan Ulang' : 'Scan Wajah',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: navyBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraGuide() {
    return Container(
      width: 116,
      height: 142,
      decoration: BoxDecoration(
        border: Border.all(
          color: navyBlue.withOpacity(0.55),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(60),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _confirmBooking,
        icon: const Icon(Icons.arrow_forward),
        label: const Text(
          'Konfirmasi Pinjaman',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: navyBlue, size: 22),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String hint = '',
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: darkText,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? mutedText : darkText,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(icon, color: navyBlue, size: 20),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: navyBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _scanFace() {
    setState(() {
      _faceVerified = !_faceVerified;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _faceVerified
              ? 'Preview wajah berhasil diverifikasi.'
              : 'Silakan lakukan verifikasi wajah kembali.',
        ),
        backgroundColor: _faceVerified ? Colors.green : primaryRed,
      ),
    );
  }

  // --- VALIDASI & MUNCULKAN POLICY DIALOG ---
  void _confirmBooking() {
    final isFormIncomplete =
        _tanggalController.text.trim().isEmpty ||
        _jamController.text.trim().isEmpty ||
        _tujuanController.text.trim().isEmpty ||
        _lokasiController.text.trim().isEmpty ||
        !_faceVerified;

    if (isFormIncomplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua data dan lakukan verifikasi wajah.'),
          backgroundColor: primaryRed,
        ),
      );
      return;
    }

    // Munculkan dialog kebijakan peminjaman terlebih dahulu
    _showPolicyDialog(context);
  }

  // 1. POP-UP KEBIJAKAN PEMINJAMAN
  void _showPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.gavel_rounded, color: navyBlue, size: 24),
              SizedBox(width: 10),
              Text(
                'Kebijakan Peminjaman',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Sebelum melanjutkan peminjaman kendaraan operasional Telkom, harap perhatikan ketentuan berikut:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  '1. Kendaraan wajib dikembalikan tepat waktu sesuai jadwal yang telah ditentukan.\n\n'
                  '2. Kebersihan interior dan eksterior kendaraan menjadi tanggung jawab peminjam selama masa pemakaian.\n\n'
                  '3. Segala bentuk pelanggaran lalu lintas atau kerusakan akibat kelalaian ditanggung oleh peminjam.\n\n'
                  '4. Dilarang merokok dan membawa barang terlarang di dalam kendaraan kantor.',
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
                Navigator.pop(context); // Tutup dialog kebijakan
                _submitBookingToSupabase(); // Kirim ke database Supabase
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: navyBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Setuju & Konfirmasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 2. SIMPAN DATA KE SUPABASE
  Future<void> _submitBookingToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User tidak ditemukan. Silakan login ulang.'), backgroundColor: primaryRed),
      );
      return;
    }

    try {
      // Ambil UUID kendaraan berdasarkan nama mobil (widget.carName)
      final vehicleRes = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('make_model', widget.carName)
          .single();

      final vehicleId = vehicleRes['id'];
      final startAtTime = '${_tanggalController.text} ${_jamController.text}';

      // Insert ke tabel bookings Supabase
      await Supabase.instance.client.from('bookings').insert({
        'employee_id': user.id,
        'vehicle_id': vehicleId,
        'purpose': _tujuanController.text.trim(),
        'destination': _lokasiController.text.trim(),
        'start_at': startAtTime,
        'status': 'active',
      });

      if (mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan peminjaman: $e'), backgroundColor: primaryRed),
        );
      }
    }
  }

  // 3. POP-UP SUKSES
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF16A34A),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Peminjaman Berhasil!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pengajuan kendaraan Anda telah direkam. Silakan ambil kunci di bagian Logistik/Pool.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lihat Riwayat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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