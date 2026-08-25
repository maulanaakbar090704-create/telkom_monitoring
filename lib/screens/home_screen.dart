import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'history_screen.dart';
import 'booking_screen.dart';
import 'profile_screen.dart'; // Import halaman profile

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variabel untuk menyimpan data user
  String userName = 'Memuat...';
  String userId = 'Memuat...';
  String? profilePicUrl;

  // Variabel Supabase (Mengganti data dummy)
  Map<String, dynamic>? activeBooking;
  List<Map<String, dynamic>> vehiclesList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupabaseData();
  }

  // Fungsi memuat semua data dari Supabase secara bersamaan
  Future<void> _loadSupabaseData() async {
    await _fetchUserData();
    await _fetchActiveBooking();
    await _fetchVehicles();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 1. Narik data user dari tabel 'profiles' & Auth
  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          userName = profile['full_name'] ?? 'Maulana Akbar';
          userId = profile['employee_no'] ?? user.email?.split('@').first ?? '123';
          profilePicUrl = user.userMetadata?['avatar_url'];
        });
      } catch (e) {
        setState(() {
          userName = user.userMetadata?['full_name'] ?? 'Maulana Akbar';
          userId = user.email?.split('@').first ?? '123';
        });
      }
    }
  }

  // 2. Cek apakah user sedang meminjam mobil (Status 'Aktif' di tabel bookings)
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

      setState(() {
        activeBooking = response;
      });
    } catch (e) {
      // Ignore error jika belum ada
    }
  }

  // 3. Ambil daftar kendaraan dari tabel 'vehicles' Supabase
  Future<void> _fetchVehicles() async {
    try {
      final response = await Supabase.instance.client
          .from('vehicles')
          .select()
          .eq('active', true);

      setState(() {
        vehiclesList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Fallback jika kosong
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      extendBody: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(context),
            _buildBodySection(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ==========================================
  // 1. BAGIAN HEADER (GRADASI, LOGO, & PROFIL)
  // ==========================================
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F3567), // Biru Gelap
            Color(0xFF8B1229), // Transisi
            Color(0xFFBB0016), // Merah Telkom
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP BAR (Logo Telkom & Profile) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  // --- LOGO TELKOM (Di-zoom & Dipangkas ruang kosongnya) ---
                  SizedBox(
                    height: 36, // Tinggi area logo
                    child: ClipRect(
                      child: Transform.scale(
                        scale: 1.0, // Angka zoom (bisa dinaikin/diturunin kalau kurang pas)
                        child: Image.asset(
                          'assets/images/Logo_telkom.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // --- Profile Icon Glass ---
                  GestureDetector(
                    onTap: () {
                      // Navigasi ke Halaman Profil dengan mulus
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            // Munculkan foto jika ada URL-nya
                            image: profilePicUrl != null && profilePicUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(profilePicUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          // Jika tidak ada foto, tampilkan icon default
                          child: profilePicUrl == null || profilePicUrl!.isEmpty
                              ? const Icon(Icons.person, color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),

            // --- WELCOME TEXT (Dinamis dari Supabase) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang, $userName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID Karyawan: $userId',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET STATUS KARTU (Dinamis: Muncul Detail Mobil jika Dipinjam) ---
  Widget _buildStatusCard() {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // JIKA ADA PEMINJAMAN AKTIF
    if (activeBooking != null) {
      final vehicle = activeBooking!['vehicles'] ?? {};
      final carName = vehicle['make_model'] ?? 'Mobil Kantor';
      final plateNumber = vehicle['registration_no'] ?? '-';
      final destination = activeBooking!['destination'] ?? '-';
      final startAt = activeBooking!['start_at'] ?? '';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                        child: const Text('SEDANG DIPINJAM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      const Icon(Icons.directions_car, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    carName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plat Nomor: $plateNumber',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tujuan: $destination',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai: $startAt',
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // JIKA TIDAK ADA MOBIL YANG DIPINJAM (KOSONG)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_car, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tidak Ada Mobil Dipinjam',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda saat ini tidak memiliki reservasi aktif\natau kendaraan yang sedang digunakan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. BAGIAN BODY (KONTEN PUTIH & LIST MOBIL)
  // ==========================================
  Widget _buildBodySection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, offset: Offset(0, -4), blurRadius: 24),
        ],
      ),
      transform: Matrix4.translationValues(0.0, -20.0, 0.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text('KETERSEDIAAN KENDARAAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF44474D), letterSpacing: 0.8)),
          ),
          const SizedBox(height: 12),
          
          // Horizontal List Kendaraan dari Tabel Supabase 'vehicles'
          SizedBox(
            height: 170,
            child: vehiclesList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(left: 20.0),
                    child: Text('Memuat daftar kendaraan...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 20),
                    clipBehavior: Clip.none,
                    itemCount: vehiclesList.length,
                    itemBuilder: (context, index) {
                      final car = vehiclesList[index];
                      final carName = car['make_model'] ?? 'Mobil';
                      final plateNumber = car['registration_no'] ?? '-';
                      final isAvailable = car['active'] == true;

                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0, bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            if (isAvailable) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingScreen(
                                    carName: carName,
                                    plateNumber: plateNumber,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$carName sedang tidak tersedia/dipakai.'),
                                  backgroundColor: const Color(0xFFBA1A1A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFC5C6CE).withOpacity(0.4)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 70,
                                  decoration: BoxDecoration(color: const Color(0xFFEDEEF0), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.directions_car, color: Color(0xFF75777E), size: 40),
                                ),
                                const SizedBox(height: 12),
                                Text(carName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF191C1E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAvailable ? const Color(0xFF82F9BE).withOpacity(0.3) : const Color(0xFFFFDAD6).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isAvailable ? 'Tersedia' : 'Dipakai',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isAvailable ? const Color(0xFF00321F) : const Color(0xFFBA1A1A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

  // ==========================================
  // 3. BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavigationBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB).withOpacity(0.9),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -1)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.history, 'History', false),
              _buildNavItem(Icons.account_circle, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    final color = isSelected ? const Color(0xFF0F3567) : const Color(0xFF44474D); 
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          // Pakai PageRouteBuilder dengan transitionDuration nol (0) biar instan
          if (label == 'History') {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const HistoryScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else if (label == 'Profile') {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const ProfileScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}