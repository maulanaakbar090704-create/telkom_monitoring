import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // Animasi Background Gradasi
  late AnimationController _bgController;
  late Animation<Alignment> _topAlignment;
  late Animation<Alignment> _bottomAlignment;

  // Animasi Munculnya Kartu
  late AnimationController _cardEnterController;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  // Animasi Sukses Login
  late AnimationController _successController;
  late Animation<double> _successScaleAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoginSuccess = false; 
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();

    // 1. Setup Animasi Background
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _topAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight), weight: 1),
    ]).animate(_bgController);
    _bottomAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft), weight: 1),
    ]).animate(_bgController);

    // 2. Setup Animasi Kartu Masuk
    _cardEnterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _cardSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardEnterController, curve: Curves.easeOutCubic));
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _cardEnterController, curve: Curves.easeIn));
    
    _cardEnterController.forward();

    // 3. Setup Animasi Centang Sukses
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _successController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardEnterController.dispose();
    _successController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // AMBIL DATA REMEMBER ME & ID TERSIMPAN
  // ==========================================
  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRemember = prefs.getBool('remember_me') ?? true;
      final savedId = prefs.getString('saved_employee_id');
      if (mounted) {
        setState(() {
          _rememberMe = savedRemember;
          if (savedId != null && savedId.isNotEmpty) {
            _emailController.text = savedId;
          }
        });
      }
    } catch (_) {}
  }

  // ==========================================
  // DIALOG BANTUAN LUPA KATA SANDI (SUPER ADMIN)
  // ==========================================
  void _showForgotPasswordDialog() {
    final currentId = _emailController.text.trim();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFFBB0016),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bantuan Super Admin IT',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Demi keamanan akun internal Telkom Akses, reset kata sandi dikonfirmasi langsung oleh Super Admin IT Fleet.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 20, color: Color(0xFFBB0016)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ID Karyawan yang diajukan:',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentId.isNotEmpty ? currentId : '(Belum diisi di formulir login)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: currentId.isNotEmpty ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Silakan hubungi Super Admin melalui WhatsApp berikut untuk verifikasi identitas dan reset kata sandi:',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              // Tombol Hubungi via WhatsApp
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final message = 'Halo Super Admin IT Fleet Telkom Akses, saya ingin mengajukan permohonan reset kata sandi akun Sistem Monitoring Kendaraan.\n\nID Karyawan: ${currentId.isNotEmpty ? currentId : '-'}\nMohon bantuannya untuk reset kata sandi. Terima kasih.';
                    final waUri = Uri.parse('https://wa.me/6281280001000?text=${Uri.encodeComponent(message)}');
                    Navigator.pop(dialogContext);
                    try {
                      if (await canLaunchUrl(waUri)) {
                        await launchUrl(waUri, mode: LaunchMode.externalApplication);
                      } else {
                        await launchUrl(waUri);
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal membuka WhatsApp secara otomatis. Silakan salin kontak admin.'),
                            backgroundColor: Color(0xFFBB0016),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Hubungi via WhatsApp',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Tombol Salin Kontak
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(
                        text: 'Super Admin IT Fleet Telkom Akses\nWhatsApp: +62 812-8000-1000\nEmail: adminfleet@telkom.co.id',
                      ),
                    );
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kontak Super Admin berhasil disalin ke clipboard!'),
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF374151)),
                  label: const Text(
                    'Salin Kontak Super Admin',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // LOGIKA LOGIN SUPABASE
  // ==========================================
  Future<void> _handleLogin() async {
    final rawId = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (rawId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Karyawan dan Kata Sandi wajib diisi!'), backgroundColor: Color(0xFFBB0016)),
      );
      return;
    }

    String emailOrId = rawId;
    if (!emailOrId.contains('@')) {
      emailOrId = '$emailOrId@telkom.com'; 
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: emailOrId,
        password: password,
      );

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, role')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profile == null) {
        if (mounted) {
          setState(() { _isLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Gagal: Data profil tidak ditemukan. Hubungi Admin.'), 
              backgroundColor: Color(0xFFBB0016)
            ),
          );
        }
        await Supabase.instance.client.auth.signOut();
        return; 
      }

      final String userRole = profile['role'] ?? 'peminjam';
      
      if (userRole == 'admin') {
        await Supabase.instance.client.auth.signOut(); 
        if (mounted) {
          setState(() { _isLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login gagal, Periksa kembali ID Karyawan dan kata sandi Anda.'), 
              backgroundColor: Color(0xFFBB0016),
              duration: Duration(seconds: 4), 
            ),
          );
        }
        return; 
      }

      // Simpan status Remember Me & ID Karyawan ke SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('saved_employee_id', rawId);
        } else {
          await prefs.remove('saved_employee_id');
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoginSuccess = true;
        });
        _successController.forward();
      }

      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()), 
          );
        }
      });

    } on AuthException {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Gagal: ID Karyawan atau kata sandi salah.'), backgroundColor: Color(0xFFBB0016)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: const Color(0xFFBB0016)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Pastikan layout menyesuaikan keyboard
      body: Stack(
        children: [
          // Background Animasi
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _topAlignment.value,
                    end: _bottomAlignment.value,
                    colors: const [
                      Color(0xFFBB0016),
                      Color(0xFF0F3567),
                    ],
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Dibungkus dengan scroll view agar aman dari keyboard
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight, // Memastikan tinggi minimal sama dengan layar
                    ),
                    child: IntrinsicHeight( // Memungkinkan penggunaan Spacer() di dalam ScrollView
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Image.asset(
                              'assets/images/Logo_telkom.png',
                              height: 50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sistem Monitoring Kendaraan',
                            style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.5),
                          ),
                          
                          const Spacer(), // Mendorong form ke tengah

                          // Animated Form / Success Card
                          FadeTransition(
                            opacity: _cardFadeAnimation,
                            child: SlideTransition(
                              position: _cardSlideAnimation,
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                  child: _isLoginSuccess 
                                      ? _buildSuccessView() 
                                      : _buildLoginForm(),
                                ),
                              ),
                            ),
                          ),
                          
                          const Spacer(), // Mendorong footer ke bawah

                          // Footer
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24.0, top: 16.0),
                            child: Column(
                              children: [
                                Text('Powered by Telkom Akses', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                SizedBox(height: 4),
                                Text('v1.0.0 (Internal System)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('LoginForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Silakan Masuk',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 24),
        
        const Text('ID Karyawan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.text,
          style: const TextStyle(color: Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Masukkan ID Karyawan',
            hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.normal),
            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFBB0016)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBB0016), width: 1.8)),
          ),
        ),
        
        const SizedBox(height: 20),

        const Text('Kata Sandi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Masukkan Kata Sandi',
            hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.normal),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFBB0016)),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF6B7280)),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBB0016), width: 1.8)),
          ),
        ),
        
        const SizedBox(height: 12),

        // Baris Remember Me (Ingat Saya) & Lupa Kata Sandi
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (val) {
                          setState(() {
                            _rememberMe = val ?? false;
                          });
                        },
                        activeColor: const Color(0xFFBB0016),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ingat Saya',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: _showForgotPasswordDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lupa Kata Sandi?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBB0016),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB0016),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Container(
      key: const ValueKey('SuccessView'),
      padding: const EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _successScaleAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF86EFAC), width: 4),
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 50),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Autentikasi Berhasil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Menyiapkan dashboard Anda...',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFFF3F4F6),
              color: Color(0xFFBB0016),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}