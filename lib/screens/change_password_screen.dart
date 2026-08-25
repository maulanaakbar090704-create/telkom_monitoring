import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3567),
        title: const Text('Ubah Kata Sandi', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFDE68A))),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFFD97706)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Kata sandi baru harus minimal 8 karakter dan mengandung angka.', style: TextStyle(color: Color(0xFF92400E), fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildPasswordField('Kata Sandi Saat Ini'),
            const SizedBox(height: 16),
            _buildPasswordField('Kata Sandi Baru'),
            const SizedBox(height: 16),
            _buildPasswordField('Konfirmasi Kata Sandi Baru'),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB0016), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Perbarui Sandi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.visibility_off, color: Colors.grey, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}