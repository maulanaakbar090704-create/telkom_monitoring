import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../history/history_screen.dart';
import '../booking/booking_screen.dart';
import '../profile/profile_screen.dart';
import '../terms/terms_screen.dart';
import '../return/return_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Data User
  String userName = 'Memuat...';
  String userId = 'Memuat...';
  String? profilePicUrl;

  // Supabase Data
  Map<String, dynamic>? activeBooking;
  List<Map<String, dynamic>> allVehicles = [];
  bool isLoading = true;

  // Filter & Search
  String _selectedFilter = 'all'; // 'all', 'available', 'in_use'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadSupabaseData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSupabaseData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    await Future.wait([
      _fetchUserData(),
      _fetchActiveBooking(),
      _fetchVehicles(),
    ]);

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          setState(() {
            userName = profile['full_name'] ?? 'Karyawan Telkom';
            userId = profile['employee_no'] ?? user.email?.split('@').first ?? '-';
            profilePicUrl = profile['avatar_url'] ?? user.userMetadata?['avatar_url'];
          });
        } else {
          setState(() {
            userName = user.userMetadata?['full_name'] ?? 'Karyawan Telkom';
            userId = user.email?.split('@').first ?? '-';
            profilePicUrl = user.userMetadata?['avatar_url'];
          });
        }
      } catch (e) {
        setState(() {
          userName = user.userMetadata?['full_name'] ?? 'Karyawan Telkom';
          userId = user.email?.split('@').first ?? '-';
        });
      }
    }
  }

  Future<void> _fetchActiveBooking() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      // 1. Cek jika peminjaman sedang aktif digunakan oleh user saat ini
      final activeRes = await Supabase.instance.client
          .from('bookings')
          .select('*, vehicles(make_model, registration_no, pic_name, pic_nik)')
          .eq('employee_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1);

      if (activeRes.isNotEmpty) {
        if (mounted) setState(() => activeBooking = activeRes.first);
        return;
      }

      // 2. Cek jika peminjaman user berstatus pending
      final pendingRes = await Supabase.instance.client
          .from('bookings')
          .select('*, vehicles(make_model, registration_no, pic_name, pic_nik)')
          .eq('employee_id', user.id)
          .inFilter('status', ['pending', 'pending_admin'])
          .order('created_at', ascending: false)
          .limit(1);

      if (pendingRes.isNotEmpty) {
        if (mounted) setState(() => activeBooking = pendingRes.first);
      } else {
        if (mounted) setState(() => activeBooking = null);
      }
    } catch (e) {
      if (mounted) setState(() => activeBooking = null);
    }
  }

  // --- MENGAMBIL STATUS MOBIL DINAMIS (TERSEDIA VS DIPAKAI) UNTUK SEMUA PLAT NOMOR ---
  Future<void> _fetchVehicles() async {
    try {
      // Ambil seluruh armada mobil
      final vehicleResponse = await Supabase.instance.client
          .from('vehicles')
          .select()
          .order('registration_no', ascending: true);

      // Ambil seluruh peminjaman yang sedang berlangsung atau pending dari semua pengguna
      final activeBookingsResponse = await Supabase.instance.client
          .from('bookings')
          .select('id, vehicle_id, plat_nomor, status, destination, purpose, start_at, employee_id')
          .inFilter('status', ['active', 'pending', 'pending_admin']);

      final activeList = List<Map<String, dynamic>>.from(activeBookingsResponse);

      // Buat mapping ketersediaan berdasarkan vehicle_id dan registration_no / plat_nomor
      final Map<dynamic, Map<String, dynamic>> activeMap = {};
      for (final b in activeList) {
        if (b['vehicle_id'] != null) {
          activeMap[b['vehicle_id']] = b;
        }
        final p = b['plat_nomor']?.toString().toUpperCase().replaceAll(' ', '');
        if (p != null && p.isNotEmpty) {
          activeMap[p] = b;
        }
      }

      final enrichedVehicles = List<Map<String, dynamic>>.from(vehicleResponse).map((v) {
        final vId = v['id'];
        final regClean = (v['registration_no'] ?? '').toString().toUpperCase().replaceAll(' ', '');
        
        final currentBooking = activeMap[vId] ?? activeMap[regClean];
        final bool isMaintenance = v['active'] == false;
        final bool isUsed = currentBooking != null && currentBooking['status'] == 'active';
        final bool isPending = currentBooking != null &&
            (currentBooking['status'] == 'pending' || currentBooking['status'] == 'pending_admin');

        // Status utama: jika mobil dipakai -> 'Dipakai', jika pending -> 'Menunggu', jika non-aktif -> 'Perawatan', lainnya -> 'Tersedia'
        String dynamicStatus = 'Tersedia';
        if (isMaintenance) {
          dynamicStatus = 'Dalam Perawatan';
        } else if (isUsed) {
          dynamicStatus = 'Dipakai';
        } else if (isPending) {
          dynamicStatus = 'Menunggu Persetujuan';
        }

        return {
          ...v,
          'current_booking': currentBooking,
          'is_used': isUsed,
          'is_pending': isPending,
          'is_maintenance': isMaintenance,
          'dynamic_status': dynamicStatus,
          'is_available': !isUsed && !isPending && !isMaintenance,
        };
      }).toList();

      if (mounted) {
        setState(() {
          allVehicles = enrichedVehicles;
        });
      }
    } catch (e) {
      // Fallback jika terjadi kendala query
      try {
        final fallback = await Supabase.instance.client.from('vehicles').select();
        if (mounted) {
          setState(() {
            allVehicles = List<Map<String, dynamic>>.from(fallback).map((v) {
              return {
                ...v,
                'dynamic_status': v['active'] == true ? 'Tersedia' : 'Dalam Perawatan',
                'is_available': v['active'] == true,
                'is_used': false,
                'is_pending': false,
                'is_maintenance': v['active'] == false,
              };
            }).toList();
          });
        }
      } catch (_) {}
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Menampilkan Bottom Sheet detail peminjaman jika mobil sedang dipakai
  void _showCarDetailSheet(Map<String, dynamic> car) {
    final booking = car['current_booking'];
    final bool isUsed = car['is_used'] == true;
    final bool isPending = car['is_pending'] == true;
    final bool isAvailable = car['is_available'] == true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car['make_model'] ?? 'Kendaraan Operasional',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 6),
                        _buildIndonesianPlateBadge(car['registration_no'] ?? '-'),
                      ],
                    ),
                  ),
                  _buildStatusBadge(
                    statusText: car['dynamic_status'] ?? 'Tersedia',
                    isAvailable: isAvailable,
                    isUsed: isUsed,
                    isPending: isPending,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Detail Informasi Peminjaman
              if (isUsed && booking != null) ...[
                _buildInfoRow(Icons.place_outlined, 'Tujuan Perjalanan', booking['destination'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.assignment_outlined, 'Keperluan Dinas', booking['purpose'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time_rounded, 'Waktu Mulai Pinjam', _formatBookingDate(booking['start_at'])),
              ] else if (isPending) ...[
                _buildInfoRow(Icons.hourglass_empty_rounded, 'Status Reservasi', 'Sedang menunggu persetujuan PIC'),
                if (booking?['destination'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.place_outlined, 'Rencana Tujuan', booking!['destination']),
                ],
              ] else ...[
                _buildInfoRow(Icons.check_circle_outline, 'Kondisi Armada', 'Siap digunakan untuk operasional dinas'),
              ],

              const SizedBox(height: 8),
              _buildInfoRow(Icons.person_pin_outlined, 'PIC Kendaraan', '${car['pic_name'] ?? 'PIC Armada'} (${car['pic_nik'] ?? '-'})'),

              const SizedBox(height: 24),

              if (isAvailable)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            carName: car['make_model'] ?? 'Mobil',
                            plateNumber: car['registration_no'] ?? '-',
                          ),
                        ),
                      ).then((_) => _loadSupabaseData());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBB0016),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Pinjam Mobil Ini Sekarang',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F3567)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHomeTab(context),
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ==========================================
  // TAB HOME
  // ==========================================
  Widget _buildHomeTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSupabaseData,
      color: const Color(0xFFBB0016),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          children: [
            _buildHeaderSection(context),
            _buildBodySection(context),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. HEADER SECTION
  // ==========================================
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3567), Color(0xFF8B1229), Color(0xFFBB0016)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Logo & Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Image.asset('assets/images/Logo_telkom.png', fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FLEET MONITORING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Telkom Akses Regional',
                                style: TextStyle(color: Colors.white70, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _onBottomNavTapped(2),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        backgroundImage: profilePicUrl != null && profilePicUrl!.isNotEmpty
                            ? NetworkImage(profilePicUrl!)
                            : null,
                        child: profilePicUrl == null || profilePicUrl!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Greeting User
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.badge_outlined, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('NIK: $userId', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Card (Active Booking user)
            _buildStatusCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Format tanggal & jam booking rapi
  String _formatBookingDate(dynamic raw) {
    if (raw == null) return '-';
    final str = raw.toString().trim();
    if (str.isEmpty) return '-';
    try {
      final dt = DateTime.parse(str).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$min';
    } catch (_) {
      return str;
    }
  }

  // Kartu Status Peminjaman Aktif User
  Widget _buildStatusCard() {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (activeBooking != null) {
      final vehicle = activeBooking!['vehicles'] ?? {};
      final carName = vehicle['make_model'] ?? 'Mobil Kantor';
      final plateNumber = vehicle['registration_no'] ?? '-';
      final destination = activeBooking!['destination'] ?? '-';
      final startAt = activeBooking!['start_at'] ?? '';
      final picName = vehicle['pic_name']?.toString() ?? 'PIC Armada';
      final status = activeBooking!['status'];
      final bool isPending = status == 'pending_admin' || status == 'pending';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPending
                      ? const Color(0xFFFDE68A).withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isPending ? 'MENUNGGU PERSETUJUAN' : 'SEDANG ANDA PINJAM',
                              style: TextStyle(
                                color: isPending ? const Color(0xFF92400E) : const Color(0xFF166534),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Icon(
                          isPending ? Icons.lock_clock_rounded : Icons.directions_car,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    carName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildIndonesianPlateBadge(plateNumber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tujuan: $destination',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isPending) ...[
                    Text(
                      'PIC Kendaraan: $picName',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFFDE68A), fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _onBottomNavTapped(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Cek Riwayat & Ambil Kunci Loker',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final formattedDate = _formatBookingDate(startAt);
                        final isVeryNarrow = constraints.maxWidth < 260;

                        if (isVeryNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Mulai: $formattedDate',
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReturnScreen(
                                        bookingId: activeBooking!['id']?.toString(),
                                        initialBooking: activeBooking,
                                      ),
                                    ),
                                  );
                                  _loadSupabaseData();
                                },
                                icon: const Icon(Icons.assignment_return_outlined, size: 14, color: Color(0xFFBB0016)),
                                label: const Text(
                                  'Kembalikan Mobil',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBB0016)),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Waktu Mulai Pinjam',
                                    style: TextStyle(fontSize: 10, color: Colors.white60),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReturnScreen(
                                      bookingId: activeBooking!['id']?.toString(),
                                      initialBooking: activeBooking,
                                    ),
                                  ),
                                );
                                _loadSupabaseData();
                              },
                              icon: const Icon(Icons.assignment_return_outlined, size: 14, color: Color(0xFFBB0016)),
                              label: const Text(
                                'Kembalikan Mobil',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBB0016)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Tampilan jika tidak ada peminjaman aktif
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car_filled_outlined, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tidak Ada Mobil Dipinjam',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pilih salah satu armada berstatus "Tersedia" di bawah untuk pengajuan dinas.',
                        style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. BODY SECTION (COUNTER, QUICK ACTIONS, SEARCH, FLEET LIST)
  // ==========================================
  Widget _buildBodySection(BuildContext context) {
    final int totalCars = allVehicles.length;
    final int availableCars = allVehicles.where((c) => c['is_available'] == true).length;
    final int usedCars = allVehicles.where((c) => c['is_used'] == true || c['is_pending'] == true).length;

    // Filter list
    final filteredCars = allVehicles.where((car) {
      final model = (car['make_model'] ?? '').toString().toLowerCase();
      final plate = (car['registration_no'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase().trim();

      final matchesQuery = q.isEmpty || model.contains(q) || plate.contains(q);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'available') {
        return car['is_available'] == true;
      } else if (_selectedFilter == 'in_use') {
        return car['is_used'] == true || car['is_pending'] == true;
      }
      return true;
    }).toList();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // 1. STATISTIK RINGKAS ARMADA (METRIC COUNTER)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Armada',
                    count: '$totalCars',
                    icon: Icons.drive_eta_rounded,
                    color: const Color(0xFF0F3567),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Tersedia',
                    count: '$availableCars',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Dipakai',
                    count: '$usedCars',
                    icon: Icons.access_time_filled_rounded,
                    color: const Color(0xFFBA1A1A),
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. QUICK ACTIONS BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.car_rental_rounded,
                      label: 'Peminjaman',
                      color: const Color(0xFFBB0016),
                      onTap: () {
                        // Filter langsung ke yang tersedia
                        setState(() => _selectedFilter = 'available');
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Loker Kunci',
                      color: const Color(0xFF0F3567),
                      onTap: () => _onBottomNavTapped(1),
                    ),
                  ),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.history_edu_rounded,
                      label: 'Riwayat',
                      color: const Color(0xFF4B5563),
                      onTap: () => _onBottomNavTapped(1),
                    ),
                  ),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.menu_book_rounded,
                      label: 'SOP Dinas',
                      color: const Color(0xFFD97706),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsConditionsScreen()));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. TITLE & SEARCH & FILTER SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KETERSEDIAAN ARMADA',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Status terkini seluruh plat nomor operasional',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF0F3567)),
                      onPressed: _loadSupabaseData,
                      tooltip: 'Perbarui Status',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari tipe mobil atau plat nomor (cth: B 1234)...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFBB0016), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Semua Armada ($totalCars)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('available', 'Tersedia ($availableCars)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('in_use', 'Dipakai ($usedCars)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. DAFTAR ARMADA MOBIL (HORIZONTAL / VERTICAL CARDS)
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(child: CircularProgressIndicator(color: Color(0xFFBB0016))),
            )
          else if (filteredCars.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada kendaraan cocok dengan "$_searchQuery"'
                          : 'Tidak ada armada pada kategori ini',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredCars.length,
              itemBuilder: (context, index) {
                final car = filteredCars[index];
                return _buildVehicleCard(car);
              },
            ),

          const SizedBox(height: 20),

          // 5. BANNER SOP & KESELAMATAN BERKENDARA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3567), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patuhi SOP & Safety First',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Periksa kondisi fisik, BBM, dan kembalikan kunci ke loker tepat waktu setelah dinas.',
                          style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // --- KARTU METRIC RINGKAS ---
  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Flexible(
                child: Text(
                  count,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- QUICK ACTION BUTTON ---
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- FILTER CHIP ---
  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBB0016) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFBB0016) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFBB0016).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  // --- KARTU MOBIL ESTETIK DENGAN STATUS DINAMIS & PLAT NOMOR ---
  Widget _buildVehicleCard(Map<String, dynamic> car) {
    final bool isAvailable = car['is_available'] == true;
    final bool isUsed = car['is_used'] == true;
    final bool isPending = car['is_pending'] == true;
    final String statusText = car['dynamic_status'] ?? 'Tersedia';
    final String plateNumber = car['registration_no'] ?? '-';
    final String makeModel = car['make_model'] ?? 'Mobil Operasional';
    final String picName = car['pic_name']?.toString() ?? 'PIC Kantor';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUsed
              ? const Color(0xFFFCA5A5).withValues(alpha: 0.6)
              : isPending
                  ? const Color(0xFFFDE68A)
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (isAvailable) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingScreen(
                  carName: makeModel,
                  plateNumber: plateNumber,
                ),
              ),
            ).then((_) => _loadSupabaseData());
          } else {
            _showCarDetailSheet(car);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon Mobil dengan background dinamis
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFFF0FDF4)
                      : isUsed
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAvailable
                        ? const Color(0xFFBBF7D0)
                        : isUsed
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFFDE68A),
                  ),
                ),
                child: Icon(
                  Icons.directions_car_filled,
                  color: isAvailable
                      ? const Color(0xFF16A34A)
                      : isUsed
                          ? const Color(0xFFBA1A1A)
                          : const Color(0xFFD97706),
                  size: 32,
                ),
              ),

              const SizedBox(width: 14),

              // Detail Mobil
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            makeModel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(
                          statusText: statusText,
                          isAvailable: isAvailable,
                          isUsed: isUsed,
                          isPending: isPending,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Plat Nomor Desain Autentik
                    _buildIndonesianPlateBadge(plateNumber),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'PIC: $picName',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- BADGE PLAT NOMOR INDONESIA ---
  Widget _buildIndonesianPlateBadge(String plateNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
      ),
      child: Text(
        plateNumber.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  // --- BADGE STATUS (TERSEDIA VS DIPAKAI) ---
  Widget _buildStatusBadge({
    required String statusText,
    required bool isAvailable,
    required bool isUsed,
    required bool isPending,
  }) {
    Color bg;
    Color fg;
    Color dotColor;

    if (isAvailable) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      dotColor = const Color(0xFF16A34A);
    } else if (isUsed) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      dotColor = const Color(0xFFDC2626);
    } else if (isPending) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
      dotColor = const Color(0xFFD97706);
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
      dotColor = Colors.grey.shade500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
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
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Beranda', 0),
              _buildNavItem(Icons.history_rounded, 'Riwayat', 1),
              _buildNavItem(Icons.person_rounded, 'Setelan', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFFBB0016) : const Color(0xFF75777E);

    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isSelected ? 26 : 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}