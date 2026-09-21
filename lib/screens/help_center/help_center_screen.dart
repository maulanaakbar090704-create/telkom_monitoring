import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  final List<Map<String, String>> _faqList = [
    {
      'question': 'Bagaimana alur peminjaman mobil dinas?',
      'answer':
          '1. Pilih mobil yang berstatus "Tersedia" di Beranda.\n2. Isi form tujuan, keperluan dinas, dan foto verifikasi.\n3. Pengajuan akan dikirim ke PIC/Pemilik kendaraan untuk disetujui.\n4. Setelah disetujui, buka loker kunci pintar menggunakan kode QR yang tersedia di aplikasi.\n5. Mobil siap digunakan untuk operasional dinas.',
      'category': 'Peminjaman',
    },
    {
      'question': 'Apa arti dari masing-masing status mobil?',
      'answer':
          '• Tersedia: Mobil siap dipinjam kapan saja.\n• Dipakai: Mobil sedang digunakan oleh staf lain untuk dinas.\n• Menunggu Persetujuan: Ada pengajuan yang sedang ditinjau oleh PIC kendaraan.\n• Dalam Perawatan: Mobil sedang diservis berkala atau perbaikan.',
      'category': 'Armada',
    },
    {
      'question': 'Bagaimana cara mengembalikan kendaraan dan kunci?',
      'answer':
          '1. Parkirkan kendaraan di area parkir kantor Telkom yang ditentukan.\n2. Buka aplikasi dan masuk ke tab "Riwayat".\n3. Pada kartu peminjaman aktif, tekan tombol "Kembalikan Mobil".\n4. Unggah foto kondisi kendaraan dan catat kilometer/BBM terakhir.\n5. Masukkan kunci kembali ke loker pintar yang ditunjuk.',
      'category': 'Pengembalian',
    },
    {
      'question': 'Bagaimana jika terjadi kendala mesin atau darurat di perjalanan?',
      'answer':
          'Tetap tenang dan amankan kendaraan ke bahu jalan. Segera hubungi PIC Kendaraan yang tertera pada detail peminjaman atau kontak Hotline Darurat Fleet Telkom Akses melalui tombol di bagian bawah halaman ini.',
      'category': 'Darurat',
    },
    {
      'question': 'Apakah staf boleh memindahtangankan kunci ke staf lain?',
      'answer':
          'Tidak diperbolehkan. Segala pertanggungjawaban penggunaan kendaraan tercatat atas nama peminjam yang tertera pada sistem. Jika staf lain memerlukan kendaraan, silakan selesaikan pengembalian terlebih dahulu lalu buat pengajuan baru.',
      'category': 'Aturan',
    },
  ];

  Future<void> _launchContact(String urlScheme) async {
    final Uri uri = Uri.parse(urlScheme);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka aplikasi kontak.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqList.where((item) {
      final q = item['question']?.toLowerCase() ?? '';
      final a = item['answer']?.toLowerCase() ?? '';
      final kw = _searchKeyword.toLowerCase().trim();
      return kw.isEmpty || q.contains(kw) || a.contains(kw);
    }).toList();

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
          'Pusat Bantuan & FAQ',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F3567), Color(0xFFBB0016)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Halo! Ada yang bisa kami bantu?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Temukan jawaban seputar peminjaman armada kantor Telkom Akses di bawah ini.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchKeyword = val),
                      decoration: InputDecoration(
                        hintText: 'Cari pertanyaan (contoh: loker, pengembalian)...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFBB0016)),
                        suffixIcon: _searchKeyword.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchKeyword = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bagian FAQ List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PERTANYAAN SERING DIAJUKAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBB0016),
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${filteredFaqs.length} Topik',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (filteredFaqs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak menemukan hasil untuk "$_searchKeyword"',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Coba kata kunci lain atau hubungi PIC Fleet kami di bawah.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredFaqs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final faq = filteredFaqs[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.help_outline, color: Color(0xFFBB0016), size: 20),
                              ),
                              title: Text(
                                faq['question'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              children: [
                                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                const SizedBox(height: 10),
                                Text(
                                  faq['answer'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 28),

                  // Kontak Bantuan Langsung
                  const Text(
                    'HUBUNGI TIM DUKUNGAN FLEET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBB0016),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildContactTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          iconColor: const Color(0xFF25D366),
                          title: 'WhatsApp Fleet Center',
                          subtitle: 'Respon cepat jam kerja (08:00 - 17:00)',
                          onTap: () => _launchContact('https://wa.me/6281234567890?text=Halo%20Admin%20Fleet%20Telkom%20Akses,%20saya%20membutuhkan%20bantuan%20terkait%20armada.'),
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                        _buildContactTile(
                          icon: Icons.phone_in_talk_outlined,
                          iconColor: const Color(0xFF0F3567),
                          title: 'Hotline Darurat Operasional',
                          subtitle: 'Panggilan darurat kendala mobil 24/7',
                          onTap: () => _launchContact('tel:08001234567'),
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                        _buildContactTile(
                          icon: Icons.mail_outline_rounded,
                          iconColor: const Color(0xFFBB0016),
                          title: 'Email Helpdesk Fleet',
                          subtitle: 'fleet.support@telkomakses.co.id',
                          onTap: () => _launchContact('mailto:fleet.support@telkomakses.co.id?subject=Bantuan%20Armada%20Telkom%20Akses'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
