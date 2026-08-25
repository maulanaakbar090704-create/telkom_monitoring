import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'home_screen.dart';

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
  bool _isLoginSuccess = false; // Trigger untuk ganti tampilan kartu ke mode sukses

  @override
  void initState() {
    super.initState();

    // 1. Setup Animasi Background (Looping)
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _topAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight), weight: 1),
    ]).animate(_bgController);
    _bottomAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(tween: AlignmentTween(begin: Alignment.bottomRight, end: Alignment.bottomLeft), weight: 1),
    ]).animate(_bgController);

    // 2. Setup Animasi Kartu Masuk (Slide Up & Fade In)
    _cardEnterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _cardSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardEnterController, curve: Curves.easeOutCubic));
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _cardEnterController, curve: Curves.easeIn));
    
    _cardEnterController.forward();

    // 3. Setup Animasi Centang Sukses (Scale / Pop In)
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

  Future<void> _handleLogin() async {
    String emailOrId = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (emailOrId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Kata Sandi wajib diisi!'), backgroundColor: Color(0xFFBB0016)),
      );
      return;
    }

    // --- LOGIK OTOMATIS TAMBAH EMAIL ---
    // Jika user hanya mengetik ID "123", otomatis ditambah "@telkom.com"
    // Ganti "@telkom.com" kalau lu daftarin akunnya pakai domain lain di Supabase (misal: @gmail.com)
    if (!emailOrId.contains('@')) {
      emailOrId = '$emailOrId@telkom.com'; 
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Proses autentikasi Supabase
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailOrId,
        password: password,
      );

      // JIKA BERHASIL: Ganti state dan mainkan animasi sukses
      setState(() {
        _isLoading = false;
        _isLoginSuccess = true;
      });
      _successController.forward();

      // Tunggu animasi sukses selesai (1.5 detik) lalu pindah ke HomeScreen
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      });

    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Gagal: Kata sandi salah atau akun tidak ditemukan.'), backgroundColor: const Color(0xFFBB0016)),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan sistem: $e'), backgroundColor: const Color(0xFFBB0016)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- 1. ANIMATED BACKGROUND GRADIENT ---
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _topAlignment.value,
                    end: _bottomAlignment.value,
                    colors: const [
                      Color(0xFFBB0016), // Merah Telkom
                      Color(0xFF0F3567), // Biru Gelap
                    ],
                  ),
                ),
              );
            },
          ),

          // --- 2. KONTEN UTAMA ---
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // --- LOGO TELKOM (DI TENGAH ATAS) ---
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
                
                const Spacer(),

                // --- 3. ANIMATED LOGIN CARD ---
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
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      // AnimatedSwitcher untuk transisi form -> sukses
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
                
                const Spacer(),

                // --- FOOTER ---
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
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
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET: TAMPILAN FORM LOGIN
  // ==========================================
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
        
        // INPUT: EMAIL / ID KARYAWAN
        const Text('Email / ID Karyawan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Masukkan ID Karyawan',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFBB0016)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBB0016), width: 1.5)),
          ),
        ),
        
        const SizedBox(height: 20),

        // INPUT: KATA SANDI
        const Text('Kata Sandi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Masukkan Kata Sandi',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFBB0016)),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBB0016), width: 1.5)),
          ),
        ),
        
        const SizedBox(height: 32),

        // TOMBOL MASUK
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

  // ==========================================
  // WIDGET: TAMPILAN SUKSES & ANIMASI CENTANG
  // ==========================================
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