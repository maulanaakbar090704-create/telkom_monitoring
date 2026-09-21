import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // Controller untuk membaca ketikan teks
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchPersonalData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  // --- MENGAMBIL DATA DARI SUPABASE ---
  Future<void> _fetchPersonalData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, employee_no, position')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          // Tarik data dari sistem. Jika kosong, biarkan kosong agar bisa diketik
          _nameController.text = data?['full_name'] ?? '';
          _nikController.text = data?['employee_no'] ?? user.email?.split('@')[0] ?? '';
          _deptController.text = data?['position'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: const Color(0xFFBB0016)),
        );
      }
    }
  }

  // --- MENYIMPAN PERUBAHAN KE SUPABASE ---
  Future<void> _saveChanges() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // Menyimpan data ke tabel profiles
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'full_name': _nameController.text.trim(),
        'employee_no': _nikController.text.trim(),
        'position': _deptController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informasi berhasil disimpan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Kembali ke halaman profil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: const Color(0xFFBB0016)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3567),
        title: const Text('Informasi Personal', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18), 
  onPressed: () => Navigator.pop(context), // Ubah onTap menjadi onPressed
),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFBB0016)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoField('Nama Lengkap', _nameController),
                const SizedBox(height: 16),
                _buildInfoField('ID Karyawan / NIK', _nikController),
                const SizedBox(height: 16),
                _buildInfoField('Departemen', _deptController),
                // Field Nomor Telepon sudah dihapus
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBB0016), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
    );
  }

  // Desain disesuaikan agar menerima Controller, bukan teks statis
  Widget _buildInfoField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // Menghubungkan kotak input dengan controller
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F3567))),
          ),
        ),
      ],
    );
  }
}