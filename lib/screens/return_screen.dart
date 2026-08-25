import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key});

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  static const Color darkNavy = Color(0xFF1B1A30);
  static const Color primaryRed = Color(0xFFD32F2F);
  
  Map<String, dynamic>? activeBooking;
  bool isLoading = true;

  // Status simulasi 4 Foto
  bool isFotoDepan = false;
  bool isFotoKanan = false;
  bool isFotoKiri = false;
  bool isFotoBelakang = false;

  @override
  void initState() {
    super.initState();
    _fetchActiveBooking();
  }

  // Tarik data mobil yang sedang dipinjam
  Future<void> _fetchActiveBooking() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select('*, vehicles(make_model, registration_no)')
          .eq('employee_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (mounted) {
        setState(() {
          activeBooking = response;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Fungsi Submit Pengembalian Mobil
  Future<void> _submitReturn() async {
    // Validasi Foto
    if (!isFotoDepan || !isFotoKanan || !isFotoKiri || !isFotoBelakang) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi ke-4 foto kendaraan terlebih dahulu!'),
          backgroundColor: primaryRed,
        ),
      );
      return;
    }

    if (activeBooking == null) return;

    try {
      // Update status di Supabase menjadi "Selesai"
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'Selesai'})
          .eq('id', activeBooking!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mobil berhasil dikembalikan!'),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke halaman sebelumnya (History)
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengembalikan mobil: $e'), backgroundColor: primaryRed),
        );
      }
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
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  // --- CARD 1: DETAIL KENDARAAN & TOMBOL SELESAI ---
  Widget _buildVehicleDetailCard() {
    final vehicle = activeBooking!['vehicles'] ?? {};
    final carName = vehicle['make_model'] ?? 'Mobil Kantor';
    final plateNumber = vehicle['registration_no'] ?? '-';
    final startAt = activeBooking!['start_at'] ?? 'Hari ini';

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(carName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(plateNumber, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: const [
                    Icon(Icons.lock, size: 12, color: primaryRed),
                    SizedBox(width: 4),
                    Text('IN USE', style: TextStyle(color: primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?q=80&w=600&auto=format&fit=crop', // Bisa diganti foto mobil asli kalau ada
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(Icons.calendar_today_outlined, 'Date', 'Today'),
              _buildInfoColumn(Icons.access_time_outlined, 'Pickup Time', startAt.toString().split(' ').last),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(Icons.location_on_outlined, 'Pickup Loc', 'HQ Parking B1'),
              _buildInfoColumn(Icons.local_gas_station_outlined, 'Initial Fuel', 'Full'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _submitReturn,
              icon: const Icon(Icons.vpn_key_outlined, color: Colors.white, size: 18),
              label: const Text('Selesai & Kembalikan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vehicle Status', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.check_circle_outline, color: primaryRed, size: 20),
              SizedBox(width: 8),
              Text('Pre-trip inspection passed', style: TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.check_circle_outline, color: primaryRed, size: 20),
              SizedBox(width: 8),
              Text('Key retrieved from locker 42', style: TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD 3: FOTO KENDARAAN (WAJIB DIKLIK) ---
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
          const Text('Foto Kendaraan', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPhotoBox('Tampilan Depan', isFotoDepan, () => setState(() => isFotoDepan = true))),
              const SizedBox(width: 12),
              Expanded(child: _buildPhotoBox('Samping Kanan', isFotoKanan, () => setState(() => isFotoKanan = true))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPhotoBox('Samping Kiri', isFotoKiri, () => setState(() => isFotoKiri = true))),
              const SizedBox(width: 12),
              Expanded(child: _buildPhotoBox('Tampilan Belakang', isFotoBelakang, () => setState(() => isFotoBelakang = true))),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Pembantu untuk Box Foto
  Widget _buildPhotoBox(String title, bool isFilled, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isFilled ? const Color(0xFFFBE9E7) : const Color(0xFFFCF5F5),
          border: Border.all(color: isFilled ? primaryRed : Colors.grey.shade300, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isFilled ? Icons.check_circle : Icons.camera_alt_outlined, color: isFilled ? primaryRed : Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(
              isFilled ? 'Tersimpan' : title,
              style: TextStyle(fontSize: 11, color: isFilled ? primaryRed : Colors.black54, fontWeight: isFilled ? FontWeight.bold : FontWeight.normal),
            ),
          ],
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}