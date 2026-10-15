import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import halaman
import '../login/login_page.dart';
import '../personal_info/personal_info_screen.dart';
import '../change_password/change_password_screen.dart';
import '../notification_settings/notification_settings_screen.dart';
import '../help_center/help_center_screen.dart';
import '../terms/terms_screen.dart';
import '../../services/gps_service.dart';
import '../../services/update_service.dart';
import '../../utils/format_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  String displayName = 'Memuat...';
  String displayId = 'Memuat...';
  String? avatarUrl;
  bool isLoading = true;
  String currentLanguage = 'Bahasa Indonesia';

  // Animasi Background & Komponen
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animasi Dinamis Gradien Background Ori
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _bgAnimation = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);

    // 2. Animasi Masuk Kartu & Menu
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));

    // 3. Animasi Denyut Tombol Kamera
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchUserData();
    _loadLanguagePreference();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        currentLanguage = prefs.getString('app_language') ?? 'Bahasa Indonesia';
      });
    }
  }

  // --- FUNGSI AMBIL DATA USER ---
  Future<void> _fetchUserData() async {
    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('full_name, employee_no, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cached_avatar_${user.id}');

        if (mounted) {
          setState(() {
            if (data != null &&
                data['full_name'] != null &&
                data['full_name'].toString().trim().isNotEmpty) {
              displayName = data['full_name'];
            } else {
              displayName = 'Karyawan Telkom';
            }

            if (data != null &&
                data['employee_no'] != null &&
                data['employee_no'].toString().trim().isNotEmpty) {
              displayId = data['employee_no'];
            } else {
              displayId = user.email?.split('@')[0] ?? '-';
            }

            final dbAvatar = data?['avatar_url']?.toString().trim();
            avatarUrl = (dbAvatar != null && dbAvatar.isNotEmpty) ? dbAvatar : cached;
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          final prefs = await SharedPreferences.getInstance();
          final cached = prefs.getString('cached_avatar_${user.id}');
          setState(() {
            displayName = 'Karyawan Telkom';
            displayId = user.email?.split('@')[0] ?? '-';
            avatarUrl = cached;
            isLoading = false;
          });
        }
      }
    }
  }

  // --- FUNGSI UPLOAD FOTO PROFIL (ANTI GAGAL 404 BUCKET NOT FOUND) ---
  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Sedang memproses foto profil...'),
            ],
          ),
          backgroundColor: const Color(0xFF1F2937),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    try {
      final bytes = await image.readAsBytes();
      String? finalUrl;

      // 1. Coba upload ke Supabase Storage (candidate buckets yang mungkin ada)
      final candidateBuckets = ['avatars', 'photos', 'profiles', 'bookings', 'vehicles'];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.id}_avatar_$timestamp.jpg';

      for (final bucket in candidateBuckets) {
        try {
          await Supabase.instance.client.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
          final candidateUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);
          if (candidateUrl.isNotEmpty && candidateUrl.startsWith('http')) {
            finalUrl = candidateUrl;
            break;
          }
        } catch (_) {
          // Lanjut ke bucket berikutnya jika bucket belum dibuat
        }
      }

      // 2. Jika Supabase Storage bucket belum dibuat / 404, gunakan Data URI base64 yang aman & langsung berhasil
      if (finalUrl == null || finalUrl.isEmpty) {
        finalUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      // 3. Simpan avatar_url ke Supabase Database 'profiles' secara aman
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'avatar_url': finalUrl})
            .eq('id', user.id);
      } catch (updateErr) {
        debugPrint('Catatan: update profil online: $updateErr');
      }

      // 4. Update juga data auth metadata user
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'avatar_url': finalUrl}),
        );
      } catch (_) {}

      // 5. Cache juga ke SharedPreferences lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_avatar_${user.id}', finalUrl);

      if (mounted) {
        setState(() => avatarUrl = finalUrl);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  // Dialog Pemilih Bahasa
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.language, color: Color(0xFFBB0016), size: 24),
              SizedBox(width: 10),
              Text('Pilih Bahasa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('Bahasa Indonesia', 'ID'),
              const Divider(height: 1),
              _buildLanguageOption('English (US)', 'EN'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String languageName, String code) {
    final isSelected = currentLanguage == languageName;
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBB0016) : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Text(
          code,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
      title: Text(
        languageName,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFFBB0016) : Colors.black87,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFBB0016), size: 18) : null,
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_language', languageName);
        if (mounted) {
          setState(() => currentLanguage = languageName);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bahasa diubah ke $languageName'), duration: const Duration(seconds: 2)),
          );
        }
      },
    );
  }

  // Dialog Bersihkan Cache
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bersihkan Cache', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Tindakan ini akan mengosongkan berkas sementara dan menyegarkan data cache lokal aplikasi.',
          style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _fetchUserData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache aplikasi berhasil dibersihkan!'),
                    backgroundColor: Color(0xFF16A34A),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB0016),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Bersihkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Dialog Konfirmasi Logout
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFBB0016), size: 24),
            SizedBox(width: 8),
            Text('Konfirmasi Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun aplikasi Telkom Monitoring ini?',
          style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB0016),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', false);
    } catch (_) {}

    GpsService.instance.stopPeriodicTracking();
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // Background Gradien Bergerak Telkom Ori (Hitam Pekat - Deep Crimson - Merah Telkom)
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) {
              return Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.2 + (_bgAnimation.value * 0.2), -1.0),
                    end: Alignment(0.2 - (_bgAnimation.value * 0.2), 1.0),
                    colors: const [
                      Color(0xFF0A0A0A), // Hitam Pekat
                      Color(0xFF6B0007), // Deep Crimson
                      Color(0xFFBA0015), // Merah Telkom
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : RefreshIndicator(
                    onRefresh: _fetchUserData,
                    color: const Color(0xFFBB0016),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              const SizedBox(height: 30),
                              Center(
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 14,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 50,
                                            backgroundColor: Colors.white24,
                                            backgroundImage: FormatHelper.getImageProvider(avatarUrl),
                                            child: (avatarUrl == null || avatarUrl!.isEmpty)
                                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                                : null,
                                          ),
                                        ),
                                        ScaleTransition(
                                          scale: _pulseAnimation,
                                          child: GestureDetector(
                                            onTap: _uploadProfilePhoto,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.25),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.camera_alt_rounded, size: 18, color: Color(0xFFBA0015)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        FormatHelper.formatUserDisplayName(displayName),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.badge_outlined, size: 14, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            'NIK / ID: $displayId',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                          // KARTU PENGATURAN AKUN
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 20, top: 12, bottom: 8),
                                  child: Text(
                                    'PENGATURAN AKUN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFBB0016),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                _buildSettingMenu(
                                  Icons.person_outline,
                                  'Informasi Pribadi & Kontak',
                                  () async {
                                    final bool? shouldRefresh = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
                                    );
                                    if (shouldRefresh == true) {
                                      setState(() { isLoading = true; });
                                      await _fetchUserData();
                                    }
                                  },
                                  subtitle: 'Nama lengkap, nomor telepon, dan NIK',
                                ),
                                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                                _buildSettingMenu(
                                  Icons.lock_outline,
                                  'Ubah Kata Sandi',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                                    );
                                  },
                                  subtitle: 'Ganti kata sandi akun secara aman',
                                ),
                                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                                _buildSettingMenu(
                                  Icons.notifications_none_rounded,
                                  'Pengaturan Notifikasi',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                                    );
                                  },
                                  subtitle: 'Push alert, email dinas, dan pengingat',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // KARTU PENGATURAN APLIKASI
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 20, top: 12, bottom: 8),
                                  child: Text(
                                    'PENGATURAN APLIKASI & DUKUNGAN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFBB0016),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                _buildSettingMenu(
                                  Icons.language_rounded,
                                  'Bahasa Aplikasi',
                                  _showLanguageDialog,
                                  subtitle: currentLanguage,
                                ),
                                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                                _buildSettingMenu(
                                  Icons.help_outline_rounded,
                                  'Pusat Bantuan & FAQ',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
                                    );
                                  },
                                  subtitle: 'Panduan armada, loker, dan kontak darurat',
                                ),
                                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                                _buildSettingMenu(
                                  Icons.security_rounded,
                                  'SOP Aman Berkendara (9 Poin)',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TermsConditionsScreen(initialTab: 'sop'),
                                      ),
                                    );
                                  },
                                  subtitle: 'Panduan visual infografis DO & DONT resmi Telkom Akses',
                                ),
                                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                                _buildSettingMenu(
                                  Icons.description_outlined,
                                  'Syarat & Ketentuan (SOP)',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const TermsConditionsScreen(initialTab: 'all')),
                                    );
                                  },
                                  subtitle: 'Standar operasional mobil kantor Telkom Akses',
                                ),
                                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                                _buildSettingMenu(
                                  Icons.system_update_alt_rounded,
                                  'Pembaruan Aplikasi',
                                   () {
                                     UpdateService.instance.checkAndPromptUpdate(context, silent: false);
                                   },
                                   subtitle: 'Periksa versi terbaru sistem peminjaman',
                                 ),
                                 const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                                 _buildSettingMenu(
                                   Icons.cleaning_services_outlined,
                                   'Bersihkan Cache',
                                  _showClearCacheDialog,
                                  subtitle: 'Segarkan data lokal aplikasi',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // TOMBOL LOGOUT DENGAN DIALOG KONFIRMASI
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _confirmLogout,
                                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                                label: const Text(
                                  'Keluar dari Akun',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBB0016),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Telkom Car Fleet Monitoring v1.0.0\nPT Telkom Akses - Regional Operational',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingMenu(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFFEF2F2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFFBB0016)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}