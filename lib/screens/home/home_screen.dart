import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/gps_service.dart';
import '../../utils/format_helper.dart';
import '../history/history_screen.dart';
import '../booking/booking_screen.dart';
import '../profile/profile_screen.dart';
import '../terms/terms_screen.dart';
import '../return/return_screen.dart';
import '../login/login_page.dart';
import '../../services/update_service.dart';
import '../../widgets/sop_carousel_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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

  // GPS Enforcement & Monitoring
  bool _isGpsReady = true;
  bool _isCheckingGps = false;
  GpsSecurityStatus _gpsSecurityStatus = GpsSecurityStatus.ready;
  StreamSubscription<ServiceStatus>? _gpsStatusSubscription;
  StreamSubscription? _bookingsRealtimeSubscription;
  Timer? _gpsWatchdogTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController(initialPage: _currentIndex);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadSupabaseData();
    _initGpsMonitoring();

    // Periksa pembaruan aplikasi secara otomatis (silent)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.instance.checkAndPromptUpdate(context, silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsStatusSubscription?.cancel();
    _bookingsRealtimeSubscription?.cancel();
    _gpsWatchdogTimer?.cancel();
    _pageController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat aplikasi dibuka kembali dari background / quick settings, langsung periksa GPS
    if (state == AppLifecycleState.resumed) {
      _checkGpsStatus();
      _fetchActiveBooking();
    }
  }

  Future<void> _initGpsMonitoring() async {
    await _checkGpsStatus();

    try {
      _gpsStatusSubscription =
          GpsService.instance.getServiceStatusStream()?.listen((status) {
        _checkGpsStatus();
      });
    } catch (_) {}

    // Berlangganan perubahan status bookings secara realtime agar langsung aktif saat disetujui PIC
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        _bookingsRealtimeSubscription = Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('employee_id', user.id)
            .listen((_) {
              _fetchActiveBooking();
            });
      } catch (_) {}
    }

    // Watchdog timer setiap 3 detik untuk memastikan GPS selalu terpantau
    _gpsWatchdogTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkGpsStatus();
    });
  }

  Future<void> _checkGpsStatus() async {
    if (_isCheckingGps) return;
    _isCheckingGps = true;

    try {
      final status = await GpsService.instance.checkGpsSecurity();
      final ready = status == GpsSecurityStatus.ready;
      if (mounted) {
        if (_isGpsReady != ready || _gpsSecurityStatus != status) {
          setState(() {
            _isGpsReady = ready;
            _gpsSecurityStatus = status;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking GPS security: $e');
    } finally {
      _isCheckingGps = false;
    }
  }

  Future<void> _handleActivateGps() async {
    await GpsService.instance.requestPermission();
    final opened = await GpsService.instance.openLocationSettings();
    if (!opened) {
      await GpsService.instance.openAppSettings();
    }
    // Verifikasi kembali setelah jeda 1 detik
    Future.delayed(const Duration(seconds: 1), _checkGpsStatus);
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

  // Session & Role Guard: Memvalidasi sesi pengguna secara ketat
  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Sesi kedaluwarsa atau hilang: redirect aman ke halaman login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        final role = profile['role'] ?? 'peminjam';
        if (role == 'admin') {
          // Akun admin tidak diizinkan masuk ke aplikasi peminjam HP
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }

        if (mounted) {
          setState(() {
            userName = profile['full_name'] ?? 'Karyawan Telkom';
            userId = profile['employee_no'] ?? user.email?.split('@').first ?? '-';
            profilePicUrl = profile['avatar_url'] ?? user.userMetadata?['avatar_url'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userName = user.userMetadata?['full_name'] ?? 'Karyawan Telkom';
            userId = user.email?.split('@').first ?? '-';
            profilePicUrl = user.userMetadata?['avatar_url'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
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
        final bookingId = activeRes.first['id']?.toString();
        if (bookingId != null && bookingId.isNotEmpty) {
          GpsService.instance.startPeriodicTracking(bookingId: bookingId);
        }
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
      // Status pending atau completed: titik koordinat GPS mati / tidak dikirim
      GpsService.instance.stopPeriodicTracking();
    } catch (e) {
      if (mounted) setState(() => activeBooking = null);
      GpsService.instance.stopPeriodicTracking();
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
        
        final currentBooking = activeMap[vId] ??
            activeMap[regClean] ??
            (activeBooking != null &&
                    (activeBooking!['vehicle_id'] == vId ||
                        (activeBooking!['plat_nomor'] ?? '').toString().toUpperCase().replaceAll(' ', '') == regClean)
                ? activeBooking
                : null);

        // 1. Baca kolom status dan kolom maintenance dari database
        final String rawStatus = (v['status'] ?? '').toString().trim().toLowerCase();
        
        // Pengecekan kolom maintenance (is_maintenance atau status maintenance/perbaikan)
        final bool isMaintenanceCol = v['is_maintenance'] == true ||
            v['maintenance'] == true ||
            rawStatus == 'maintenance' ||
            rawStatus == 'perbaikan' ||
            rawStatus == 'dalam perbaikan' ||
            rawStatus == 'perawatan' ||
            rawStatus == 'dalam perawatan' ||
            rawStatus == 'servis';

        // Pengecekan kolom status (terpakai / in_use / dipakai) atau adanya booking aktif
        final bool isTerpakaiCol = rawStatus == 'terpakai' ||
            rawStatus == 'dipakai' ||
            rawStatus == 'in_use' ||
            rawStatus == 'used';

        final bool hasActiveBooking = currentBooking != null && currentBooking['status'] == 'active';
        final bool hasPendingBooking = currentBooking != null &&
            (currentBooking['status'] == 'pending' || currentBooking['status'] == 'pending_admin');

        // Status Mobil Terpakai: jika kolom status terpakai/in_use ATAU ada peminjaman aktif
        final bool isUsed = !isMaintenanceCol && (isTerpakaiCol || hasActiveBooking);

        // Status Mobil Pending: jika ada pengajuan peminjaman
        final bool isPending = !isMaintenanceCol && !isUsed && hasPendingBooking;

        // Status Mobil Dalam Perbaikan/Perawatan: jika kolom maintenance aktif
        final bool isMaintenance = isMaintenanceCol;

        // Status Tersedia: jika tidak ada status peminjaman, tidak ada maintenance, dan tidak terpakai
        final bool isAvailable = !isMaintenance && !isUsed && !isPending;

        String dynamicStatus = 'Tersedia';
        if (isMaintenance) {
          dynamicStatus = rawStatus.contains('perawatan') ? 'Dalam Perawatan' : 'Dalam Perbaikan';
        } else if (isUsed) {
          dynamicStatus = rawStatus == 'terpakai' ? 'Terpakai' : 'Dipakai';
        } else if (isPending) {
          dynamicStatus = 'Menunggu Persetujuan';
        } else {
          dynamicStatus = 'Tersedia';
        }

        return {
          ...v,
          'current_booking': currentBooking,
          'is_used': isUsed,
          'is_pending': isPending,
          'is_maintenance': isMaintenance,
          'dynamic_status': dynamicStatus,
          'is_available': isAvailable,
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
              final rawStatus = (v['status'] ?? '').toString().trim().toLowerCase();
              final isMaint = v['is_maintenance'] == true ||
                  v['maintenance'] == true ||
                  rawStatus == 'maintenance' ||
                  rawStatus == 'perbaikan' ||
                  rawStatus == 'dalam perbaikan' ||
                  rawStatus == 'perawatan' ||
                  rawStatus == 'servis';

              final isUsed = !isMaint && (rawStatus == 'terpakai' || rawStatus == 'dipakai' || rawStatus == 'in_use' || rawStatus == 'used');
              final isAvail = !isMaint && !isUsed;

              String dynStatus = 'Tersedia';
              if (isMaint) {
                dynStatus = rawStatus.contains('perawatan') ? 'Dalam Perawatan' : 'Dalam Perbaikan';
              } else if (isUsed) {
                dynStatus = rawStatus == 'terpakai' ? 'Terpakai' : 'Dipakai';
              } else {
                dynStatus = 'Tersedia';
              }

              return {
                ...v,
                'dynamic_status': dynStatus,
                'is_available': isAvail,
                'is_used': isUsed,
                'is_pending': false,
                'is_maintenance': isMaint,
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
              ] else if (isUsed) ...[
                _buildInfoRow(Icons.directions_car_rounded, 'Status Armada', 'Mobil sedang aktif digunakan untuk dinas'),
              ] else if (car['is_maintenance'] == true) ...[
                _buildInfoRow(Icons.build_circle_outlined, 'Status Armada', 'Mobil sedang dalam perbaikan / perawatan'),
                if (car['maintenance_reason'] != null && car['maintenance_reason'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.note_alt_outlined, 'Catatan Perbaikan', car['maintenance_reason'].toString().trim()),
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
        Icon(icon, size: 18, color: const Color(0xFFBA0015)),
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
    return Stack(
      children: [
        Scaffold(
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
        ),
        if (!_isGpsReady) _buildGpsEnforcerOverlay(),
      ],
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
    return _AnimatedFleetBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar: Logo (Kiri), Fleetlok (Tepat di Tengah), & Avatar (Kanan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                height: 38,
                child: Row(
                  children: [
                    // Kiri: Logo Telkom Akses (mentok kiri)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/images/Logo_telkom.png',
                          height: 26,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Tengah: Tulisan Fleetlok (100% presisi lurus di tengah layar)
                    const Text(
                      'Fleetlok',
                      style: TextStyle(
                        color: Color(0xFFE50914),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    // Kanan: Profile Avatar (mentok kanan)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _onBottomNavTapped(2),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: Colors.white24,
                              backgroundImage: FormatHelper.getImageProvider(profilePicUrl),
                              child: profilePicUrl == null || profilePicUrl!.isEmpty
                                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Greeting User (Centered, rapi & lurus dengan Fleetlok)
            Center(
              child: Column(
                children: [
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE50914), // Merah Bold
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      FormatHelper.formatUserDisplayName(userName),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white, // Putih bersih, kontras tinggi & terbaca jelas
                        letterSpacing: 0.4,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Text(
                      'NIK: $userId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Card (Active Booking user / Frosted Glass Box)
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
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isPending
                      ? const Color(0xFFFDE68A).withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.35),
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
                  if (!isPending) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Armada Sedang Digunakan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
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
    final int maintenanceCars = allVehicles.where((c) => c['is_maintenance'] == true).length;

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
      } else if (_selectedFilter == 'maintenance') {
        return car['is_maintenance'] == true;
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

          // 1. STATISTIK RINGKAS ARMADA (METRIC COUNTER - TANPA GARIS / BORDERLESS)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Armada',
                    count: '$totalCars',
                    icon: Icons.drive_eta_rounded,
                    color: const Color(0xFF1E293B),
                    bgColor: const Color(0xFFF1F5F9),
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
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
                    isSelected: _selectedFilter == 'available',
                    onTap: () => setState(() => _selectedFilter = 'available'),
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
                    isSelected: _selectedFilter == 'in_use',
                    onTap: () => setState(() => _selectedFilter = 'in_use'),
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
                      color: const Color(0xFFBA0015),
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

          const SizedBox(height: 20),

          // 2.5 BANNER SOP AMAN BERKENDARA (ROTASI OTOMATIS BERGANTI TIAP DETIK)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: SopCarouselBanner(),
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
                      icon: const Icon(Icons.refresh, size: 20, color: Color(0xFFBA0015)),
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
                      _buildFilterChip('all', 'Semua ($totalCars)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('available', 'Tersedia ($availableCars)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('in_use', 'Dipakai ($usedCars)'),
                      if (maintenanceCars > 0) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip('maintenance', 'Perbaikan ($maintenanceCars)'),
                      ],
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
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A0A0A), Color(0xFF6B0007)],
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
                            'Patuhi SOP, GPS & Safety First',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Wajib GPS akurasi tinggi, larangan Fake GPS, jaga BBM, dan kembalikan tepat waktu.',
                            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // --- KARTU METRIC RINGKAS (TANPA GARIS / BORDERLESS) ---
  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          // JANGAN DIGARISIN: Tanpa border line sama sekali
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
                  : car['is_maintenance'] == true
                      ? const Color(0xFFFDBA74)
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
                          : isPending
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAvailable
                        ? const Color(0xFFBBF7D0)
                        : isUsed
                            ? const Color(0xFFFECACA)
                            : isPending
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFFED7AA),
                  ),
                ),
                child: Icon(
                  car['is_maintenance'] == true
                      ? Icons.build_circle_rounded
                      : Icons.directions_car_filled,
                  color: isAvailable
                      ? const Color(0xFF16A34A)
                      : isUsed
                          ? const Color(0xFFBA1A1A)
                          : isPending
                              ? const Color(0xFFD97706)
                              : const Color(0xFFEA580C),
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
      // Perawatan / Perbaikan
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFC2410C);
      dotColor = const Color(0xFFEA580C);
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

  // ==========================================
  // GPS ENFORCER OVERLAY (STRICT LOCK, FAKE GPS & DASHBOARD)
  // ==========================================
  Widget _buildGpsEnforcerOverlay() {
    final bool isMock = _gpsSecurityStatus == GpsSecurityStatus.mockDetected;
    final bool hasActiveLoan =
        activeBooking != null && activeBooking!['status'] == 'active';

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black.withValues(alpha: 0.90),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: isMock
                    ? _buildMockLocationSecurityLockContent()
                    : (hasActiveLoan
                        ? _buildActiveLoanStrictLockContent()
                        : _buildDashboardGpsRequiredContent()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tampilan Penguncian Keamanan: Fake GPS / Mock Location Terdeteksi
  Widget _buildMockLocationSecurityLockContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0B12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF2E54),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2E54).withValues(alpha: 0.35),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFF2E54), Color(0xFF880016)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2E54).withValues(alpha: 0.6),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.gpp_bad_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFF2E54).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF2E54).withValues(alpha: 0.6)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFFFA0B2)),
                SizedBox(width: 6),
                Text(
                  'SECURITY LOCKOUT â€¢ FAKE GPS DETECTED',
                  style: TextStyle(
                    color: Color(0xFFFFA0B2),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'LOKASI PALSU TERDETEKSI!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Sistem mendeteksi aplikasi Fake GPS atau Mock Location provider aktif di HP Anda. Demi kepatuhan audit dan keamanan armada kantor, manipulasi lokasi dilarang keras.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Langkah Penyelesaian:',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Matikan atau uninstal aplikasi Fake GPS / FlyGPS.\n'
                  '2. Nonaktifkan "Pilih aplikasi lokasi tiruan" di Opsi Pengembang (Developer Options).\n'
                  '3. Tekan tombol segarkan di bawah untuk verifikasi ulang.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                await GpsService.instance.openAppSettings();
                _checkGpsStatus();
              },
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
              label: const Text(
                'BUKA PENGATURAN PERANGKAT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB0016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _checkGpsStatus,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
              label: const Text(
                'Saya Sudah Mematikan Fake GPS',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan Penguncian Ketat Peminjaman Aktif (GPS Dilarang Dimatikan)
  Widget _buildActiveLoanStrictLockContent() {
    final vehicle = activeBooking!['vehicles'] ?? {};
    final carName = vehicle['make_model'] ?? 'Mobil Dinas Telkom';
    final plateNumber =
        vehicle['registration_no'] ?? activeBooking!['plat_nomor'] ?? '-';
    final destination = activeBooking!['destination'] ?? '-';
    final startAt = activeBooking!['start_at'] ?? '';

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF19070A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBB0016).withValues(alpha: 0.4),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Peringatan Berdenyut
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFEF4444), Color(0xFF7F1D1D)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Label Status Darurat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: Color(0xFFFCA5A5)),
                SizedBox(width: 6),
                Text(
                  'KUNCI LOKASI OPERASIONAL AKTIF',
                  style: TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'GPS WAJIB DIAKTIFKAN!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Peminjaman mobil dinas Anda saat ini berstatus SEDANG BERJALAN di sistem. Lokasi GPS pada perangkat TIDAK DAPAT DIMATIKAN.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Kartu Informasi Kendaraan yang Sedang Dipinjam
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        carName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildIndonesianPlateBadge(plateNumber),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: Colors.white60),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tujuan: $destination',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.white60),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Mulai: ${_formatBookingDate(startAt)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kotak Informasi SOP
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: Color(0xFFF87171)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sesuai ketentuan monitoring Telkom Akses, lokasi HP wajib tetap menyala sampai status peminjaman di Supabase diselesaikan ("Completed").',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Tombol Utama: Aktifkan GPS Sekarang
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleActivateGps,
              icon: const Icon(Icons.location_on_rounded, color: Colors.white),
              label: const Text(
                'AKTIFKAN GPS SEKARANG',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB0016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Sinkronisasi Status Supabase
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () async {
                await _loadSupabaseData();
                await _checkGpsStatus();
              },
              icon: const Icon(Icons.sync_rounded, size: 18, color: Colors.white70),
              label: const Text(
                'Sudah Dikembalikan? Periksa Supabase',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Tombol Cek Ulang GPS
          TextButton(
            onPressed: _checkGpsStatus,
            child: const Text(
              'Sudah menyalakan GPS? Ketuk di sini untuk segarkan',
              style: TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 11.5,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan Wajib GPS Saat Masuk Dashboard (Tanpa Peminjaman Aktif)
  Widget _buildDashboardGpsRequiredContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3567).withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Lokasi
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0F3567)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.near_me_disabled_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
              ),
            ),
            child: const Text(
              'TELKOM AKSES REGIONAL',
              style: TextStyle(
                color: Color(0xFF7DD3FC),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Aktivasi GPS Diperlukan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Untuk menggunakan aplikasi peminjaman mobil dinas dan mengakses seluruh fitur dashboard, Anda wajib mengaktifkan layanan lokasi (GPS) pada HP Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),

          // Tombol Aktifkan GPS
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleActivateGps,
              icon: const Icon(Icons.my_location_rounded, color: Colors.white),
              label: const Text(
                'AKTIFKAN GPS SEKARANG',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB0016),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Cek Ulang
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _checkGpsStatus,
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: Colors.white70),
              label: const Text(
                'Saya Sudah Mengaktifkan GPS',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
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

  
}

/// Background gradien dinamis hitam pekat ke merah sesuai permintaan & foto referensi
/// (Hitam #0A0A0A di atas, Deep Crimson #6B0007 di tengah, Merah #BA0015 di bawah).
class _AnimatedFleetBackground extends StatefulWidget {
  final Widget child;
  const _AnimatedFleetBackground({required this.child});

  @override
  State<_AnimatedFleetBackground> createState() => _AnimatedFleetBackgroundState();
}

class _AnimatedFleetBackgroundState extends State<_AnimatedFleetBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        // Animasi halus pergeseran gradien hitam pekat ke merah
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.15 * t, -1.0),
              end: Alignment(0.15 * t, 1.0),
              colors: const [
                Color(0xFF0A0A0A), // HITAM PEKAT
                Color(0xFF6B0007), // DEEP CRIMSON
                Color(0xFFBA0015), // MERAH TELKOM
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}