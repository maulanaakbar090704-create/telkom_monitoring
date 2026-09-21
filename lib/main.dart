import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login/login_page.dart';
import 'screens/home/home_screen.dart';

void main() async {
  // Wajib ditambahkan sebelum inisialisasi Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://jwybjxbwzcweiumokrrd.supabase.co',
    publishableKey: 'sb_publishable_okOPH2sIycoC39rsgACBDA_Yg8atOpj',
  );

  // Periksa sesi dan preferensi Remember Me
  final prefs = await SharedPreferences.getInstance();
  final bool rememberMe = prefs.getBool('remember_me') ?? false;
  final session = Supabase.instance.client.auth.currentSession;

  Widget initialScreen = const LoginScreen();
  if (rememberMe && session != null) {
    initialScreen = const HomeScreen();
  } else if (!rememberMe && session != null) {
    // Jika tidak memilih Remember Me, sign out sesi saat app ditutup/dibuka kembali
    await Supabase.instance.client.auth.signOut();
  }

  runApp(TelkomFleetApp(initialScreen: initialScreen));
}

class TelkomFleetApp extends StatelessWidget {
  final Widget initialScreen;
  const TelkomFleetApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring Mobil Kantor',
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}
