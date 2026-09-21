import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';

class SeederScreen extends StatefulWidget {
  const SeederScreen({super.key});

  @override
  State<SeederScreen> createState() => _SeederScreenState();
}

class _SeederScreenState extends State<SeederScreen> {
  bool _isLoading = false;
  int _totalData = 0;
  int _berhasil = 0;
  int _gagal = 0;
  String _status = 'Siap mengeksekusi...';
  String _lastError = '';

  Future<void> _jalankanSeeder() async {
    setState(() {
      _isLoading = true;
      _berhasil = 0;
      _gagal = 0;
      _lastError = '';
      _status = 'Membaca file CSV...';
    });

    try {
      final String csvString = await rootBundle.loadString('assets/data/karyawan_clean.csv');
      
      List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
      ).convert(csvString);

      if (csvTable.isNotEmpty) csvTable.removeAt(0);

      setState(() {
        _totalData = csvTable.length;
        _status = 'Memulai proses upload (Mode Aman)...';
      });

      final client = Supabase.instance.client;
      
      for (int i = 0; i < csvTable.length; i++) {
        final row = csvTable[i];
        
        if (row.isNotEmpty) {
          // 1. Pembersihan NIK: Buang spasi, titik, koma, huruf tak kasat mata
          final rawNik = row[0].toString();
          final nik = rawNik.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').trim();
          
          final nama = row.length > 1 ? row[1].toString().trim() : 'Karyawan';

          if (nik.isNotEmpty) {
            try {
              final email = '$nik@telkom.com';
              final password = 'telkom123';

              // 2. Daftar ke Auth
              final authResponse = await client.auth.signUp(
                email: email,
                password: password,
              );

              // 3. Update Profiles (menggunakan update krn barisnya sdh dibuat oleh Trigger SQL)
              if (authResponse.user != null) {
  await client.from('profiles').upsert({
    'id': authResponse.user!.id,
    'employee_no': nik,
    'full_name': nama,
    'role': 'peminjam'
    // Baris 'position' dihapus agar tidak terjadi error
  });
  
  setState(() => _berhasil++);
}
            } catch (e) {
              setState(() {
                _gagal++;
                // Menangkap pesan error asli dari Supabase
                _lastError = 'Gagal NIK $nik: ${e.toString()}';
              });
              debugPrint(_lastError);
            }
          }
        }
        
        setState(() {
          _status = 'Memproses data ke-${i + 1} dari $_totalData...';
        });
        
        // 4. JEDA ANTI-SPAM SUPABASE (Sangat Penting)
        // Menunggu 0.8 detik setiap kali mendaftar agar tidak diblokir
        await Future.delayed(const Duration(milliseconds: 800)); 
      }

      setState(() {
        _status = 'Selesai! Berhasil: $_berhasil, Gagal: $_gagal.';
      });

    } catch (e) {
      setState(() {
        _status = 'Error Fatal Sistem: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Seeder - Karyawan'),
        backgroundColor: const Color(0xFFBB0016),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 80, color: Color(0xFF0F3567)),
              const SizedBox(height: 24),
              const Text(
                'Import Mode Aman (Anti-Spam)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              if (_isLoading) 
                const CircularProgressIndicator(color: Color(0xFFBB0016)),
              
              const SizedBox(height: 24),
              Text(_status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              
              const SizedBox(height: 16),
              Text('Total Data CSV: $_totalData', style: const TextStyle(color: Colors.grey, fontSize: 16)),
              Text('Berhasil (Auth & Profile): $_berhasil', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Gagal: $_gagal', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),

              if (_lastError.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(_lastError, style: TextStyle(color: Colors.red.shade900, fontSize: 12), textAlign: TextAlign.center),
                )
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _jalankanSeeder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3567),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mulai Import Data'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}