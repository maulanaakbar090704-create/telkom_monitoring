import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Import halaman
import 'home_screen.dart';
import 'history_screen.dart';
import 'login_page.dart'; // Pastikan import login_screen
import 'personal_info_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String displayName = 'Memuat...';
  String displayId = 'Memuat...';
  String? avatarUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- FUNGSI NARIK DATA DARI SUPABASE ---
  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Otomatis ngambil ID dari format email "123@telkom.com" -> jadi "123"
      String extractedId = user.email?.split('@')[0] ?? '-';

      try {
        // Coba narik nama dan foto dari tabel database (Misal nama tabel lu: 'profiles' atau 'employees')
        // *CATATAN: Ubah 'profiles' sesuai nama tabel lu di database kalau ada.
        final data = await Supabase.instance.client
            .from('profiles') 
            .select('full_name, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            displayId = extractedId;
            displayName = (data != null && data['full_name'] != null) ? data['full_name'] : 'Karyawan Telkom';
            avatarUrl = data?['avatar_url'];
            isLoading = false;
          });
        }
      } catch (e) {
        // Kalau tabel belum ada/error, pakai data default biar aplikasi gak crash
        if (mounted) {
          setState(() {
            displayId = extractedId;
            displayName = 'Karyawan Telkom';
            isLoading = false;
          });
        }
      }
    }
  }

  // --- FUNGSI UPLOAD FOTO PROFIL ---
  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sedang mengunggah foto...'), backgroundColor: Colors.blue),
      );

      final user = Supabase.instance.client.auth.currentUser;
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${user!.id}_avatar.$fileExt';

      // Upload ke bucket 'avatars' di Supabase Storage (Pastikan lu udah bikin bucket bernama 'avatars' di Supabase)
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      // Dapatkan URL gambar
      final String publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);

      // Simpan URL ke tabel profil
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'avatar_url': publicUrl,
      });

      setState(() => avatarUrl = publicUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> _handleLogout() async {
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
          // Background Merah - Biru
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F3567), Color(0xFFBB0016)],
              ),
            ),
          ),
          
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        
                        // FOTO PROFIL & NAMA
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white24,
                                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                                    child: avatarUrl == null
                                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                                        : null,
                                  ),
                                  GestureDetector(
                                    onTap: _uploadProfilePhoto,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit, size: 16, color: Color(0xFF0F3567)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                displayName,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.badge_outlined, size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text('ID: $displayId', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // ACCOUNT SETTINGS CARD
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 20, top: 12, bottom: 8),
                                child: Text('ACCOUNT SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBB0016), letterSpacing: 1.0)),
                              ),
                              _buildSettingMenu(Icons.person_outline, 'Personal Information', () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen()));
                              }),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                              _buildSettingMenu(Icons.lock_outline, 'Change Password', () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
                              }),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                              _buildSettingMenu(Icons.notifications_none, 'Notification Settings', () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                              }),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // APP SETTINGS CARD
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 20, top: 12, bottom: 8),
                                child: Text('APP SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBB0016), letterSpacing: 1.0)),
                              ),
                              _buildSettingMenu(Icons.language, 'Language', () {}, subtitle: 'Bahasa Indonesia'),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                              _buildSettingMenu(Icons.help_outline, 'Help Center', () {}),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                              _buildSettingMenu(Icons.description_outlined, 'Terms & Conditions', () {}),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // TOMBOL LOGOUT
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout, color: Colors.white),
                              label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBB0016),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 100), // Spacing buat navbar
                      ],
                    ),
                  ),
          ),
        ],
      ),
      
      // BOTTOM NAVBAR (Sama seperti History & Home, delay 0)
      bottomNavigationBar: Container(
        height: 64 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'Home', false, context),
            _buildNavItem(Icons.history, 'History', false, context), 
            _buildNavItem(Icons.person, 'Profile', true, context),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingMenu(IconData icon, String title, VoidCallback onTap, {String? subtitle}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: const Color(0xFFBB0016)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, BuildContext context) {
    final color = isSelected ? const Color(0xFF0F3567) : const Color(0xFF9CA3AF);
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          if (label == 'Home') {
            Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a1, a2) => const HomeScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero));
          } else if (label == 'History') {
            Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a1, a2) => const HistoryScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero));
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}