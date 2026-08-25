import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_page.dart';

void main() async {
  // Wajib ditambahkan sebelum inisialisasi Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://jwybjxbwzcweiumokrrd.supabase.co',
    anonKey: 'sb_publishable_okOPH2sIycoC39rsgACBDA_Yg8atOpj',
  );

  runApp(const TelkomFleetApp());
}

class TelkomFleetApp extends StatelessWidget {
  const TelkomFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring Mobil Kantor',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), // Mulai dari Login Page
    );
  }
}