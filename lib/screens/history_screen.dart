import 'package:flutter/material.dart';
import 'package:telkom_car_monitoring/screens/home_screen.dart';
import 'dart:ui';
import 'return_screen.dart';
import 'profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Animasi denyut (pulse) untuk titik merah pada status "Sedang Dipinjam"
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil riwayat peminjaman dari Supabase
  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('bookings')
        .select('*, vehicles(make_model, registration_no)')
        .eq('employee_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F7), // Background abu-kemerahan
      extendBody: true,
      
      body: Stack(
        children: [
          // 1. HEADER GRADIENT
          Container(
            height: 260, // Ketinggian background merah-biru
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFBB0016), // Merah Telkom
                  Color(0xFF0F3567), // Biru Gelap
                ], 
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 2. KONTEN SCROLLABLE
          SafeArea(
            bottom: false,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: Text(
                        'Gagal memuat riwayat: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                final historyList = snapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- TEKS HEADER ---
                      const Text(
                        'Riwayat Peminjaman',
                        style: TextStyle(
                          fontSize: 26, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pantau aktivitas peminjaman kendaraan operasional Anda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36), 

                      // --- KONDISI JIKA KOSONG ---
                      if (historyList.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.history, size: 40, color: Color(0xFF6B7280)),
                              SizedBox(height: 12),
                              Text(
                                'Belum Ada Riwayat Peminjaman',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Semua pengajuan peminjaman mobil kantor Anda akan muncul di sini secara otomatis.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        )
                      else
                        // --- RENDER LIST DATA DARI SUPABASE ---
                        ...historyList.map((item) {
                          final status = item['status'] ?? 'Selesai';
                          final vehicle = item['vehicles'] ?? {};
                          final carName = vehicle['make_model'] ?? 'Mobil Kantor';
                          final destination = item['destination'] ?? '-';
                          final startAt = item['start_at'] ?? '-';
                          final adminNote = item['admin_note']; // Nangkep catatan dari admin

                          if (status == 'active') { // Status "Sedang Dipinjam"
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildActiveLoanCard(
                                context: context,
                                carName: carName,
                                date: startAt,
                                destination: destination,
                              ),
                            );
                          } else { // Status Selesai
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildCompletedLoanCard(
                                carName: carName,
                                date: startAt,
                                adminNote: adminNote, // Passing catatan ke UI
                              ),
                            );
                          }
                        }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Container(
        height: 64 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'Home', false, context),
            _buildNavItem(Icons.history, 'History', true, context), 
            _buildNavItem(Icons.person_outline, 'Profile', false, context),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET: Kartu Prioritas (Sedang Dipinjam)
  // ==========================================
  Widget _buildActiveLoanCard({
    required BuildContext context,
    required String carName,
    required String date,
    required String destination,
  }) {
    // Dibungkus InkWell supaya bisa di-klik dan pindah ke ReturnScreen
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReturnScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.red.shade100, width: 1.5), 
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _pulseAnimation,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFBA1A1A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'SEDANG DIPINJAM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBA1A1A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?q=80&w=150&auto=format&fit=crop',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                carName,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200, thickness: 1),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tujuan',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    destination,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReturnScreen()),
                    );
                  },
                  icon: const Icon(Icons.assignment_return_outlined, size: 20, color: Colors.white),
                  label: const Text(
                    'Kembalikan Mobil',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB0016),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET: Kartu Riwayat Yang Sudah Selesai
  // ==========================================
  Widget _buildCompletedLoanCard({
    required String carName,
    required String date,
    String? adminNote, // Parameter menangkap note
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF6B7280)),
                          SizedBox(width: 4),
                          Text(
                            'SELESAI',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(carName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 6),
                        Text(date, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                child: const Icon(Icons.directions_car_outlined, color: Color(0xFFBB0016), size: 22),
              ),
            ],
          ),
          
          // Tampilan pesan admin kalau tidak kosong
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), 
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Catatan Tim Kantor:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                        const SizedBox(height: 4),
                        Text(adminNote, style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET: Helper untuk Navigasi Bawah
  // ==========================================
  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    BuildContext context,
  ) {
    final color = isSelected ? const Color(0xFF0F3567) : const Color(0xFF9CA3AF);
    return GestureDetector(
      onTap: () {
        if (label == 'Home') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        } else if (label == 'Profile') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}