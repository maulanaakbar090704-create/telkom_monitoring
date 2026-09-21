import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3567),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Syarat & Ketentuan',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3567), Color(0xFFBB0016)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOP KENDARAAN DINAS',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Standar Operasional Prosedur Penggunaan Armada PT Telkom Akses.',
                          style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              number: '1',
              title: 'Ketentuan Umum Peminjam',
              items: [
                'Peminjam adalah karyawan aktif PT Telkom Akses yang memiliki NIK dan akun terdaftar pada sistem.',
                'Peminjam wajib memiliki Surat Izin Mengemudi (SIM A/B) yang masih berlaku selama periode penggunaan.',
                'Kunci kendaraan hanya boleh diambil dan dioperasikan oleh karyawan yang tercatat pada sistem reservasi.',
              ],
            ),

            _buildSection(
              number: '2',
              title: 'Penggunaan & Tujuan Operasional',
              items: [
                'Kendaraan dinas hanya diperuntukkan bagi keperluan operasional pekerjaan resmi perusahaan.',
                'Dilarang keras menyalahgunakan armada untuk keperluan pribadi di luar instruksi kedinasan atau tanpa izin PIC.',
                'Area operasional perjalanan wajib sesuai dengan tujuan yang tercantum pada formulir pengajuan.',
              ],
            ),

            _buildSection(
              number: '3',
              title: 'Pemeliharaan, BBM, & Kebersihan',
              items: [
                'Peminjam wajib menjaga kebersihan interior maupun eksterior kendaraan selama dan sesudah penggunaan.',
                'Dilarang merokok di dalam kabin mobil dinas.',
                'Level bahan bakar (BBM) saat pengembalian minimal harus setara dengan kondisi awal peminjaman.',
                'Segala bentuk kendala mekanik atau indikator darurat wajib segera dilaporkan kepada PIC kendaraan.',
              ],
            ),

            _buildSection(
              number: '4',
              title: 'Keselamatan, Pelanggaran, & Tilang',
              items: [
                'Peminjam wajib mematuhi seluruh peraturan lalu lintas yang berlaku di Republik Indonesia.',
                'Segala denda tilang konvensional maupun ETLE (Electronic Traffic Law Enforcement) yang terjadi pada rentang waktu peminjaman menjadi tanggung jawab penuh pengemudi.',
                'Perusahaan tidak bertanggung jawab atas barang-barang pribadi yang tertinggal di dalam kendaraan.',
              ],
            ),

            _buildSection(
              number: '5',
              title: 'Prosedur Pengembalian & Loker Pintar',
              items: [
                'Kendaraan harus dikembalikan tepat waktu sesuai estimasi yang disetujui untuk menjaga ketersediaan armada staf lain.',
                'Pengembalian dilakukan dengan menyelesaikan form pengembalian di aplikasi dan mengunggah foto kondisi fisik kendaraan.',
                'Kunci wajib dikembalikan ke slot loker pintar yang ditentukan dan loker dipastikan terkunci sempurna.',
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFBB0016), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dengan melakukan reservasi peminjaman armada pada aplikasi ini, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan di atas.',
                      style: TextStyle(color: Color(0xFF991B1B), fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F3567),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle, size: 6, color: Color(0xFFBB0016)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.45),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
