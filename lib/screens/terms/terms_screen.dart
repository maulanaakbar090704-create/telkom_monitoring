import 'package:flutter/material.dart';
import 'package:telkom_monitoring/widgets/sop_carousel_banner.dart';

class TermsConditionsScreen extends StatefulWidget {
  final String initialTab;
  const TermsConditionsScreen({super.key, this.initialTab = 'sop'});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialTab;
  }

  final List<Map<String, dynamic>> _sections = [
    {
      'number': '1',
      'category': 'umum',
      'title': 'Ketentuan Umum Peminjam',
      'badge': 'SYARAT DASAR',
      'badgeColor': const Color(0xFFBA0015),
      'items': [
        'Peminjam adalah karyawan aktif PT Telkom Akses yang memiliki akun terverifikasi dan NIK terdaftar pada sistem monitoring.',
        'Peminjam wajib memiliki Surat Izin Mengemudi (SIM A/B) yang masih berlaku sah selama periode penggunaan armada dinas.',
        'Kunci kendaraan hanya boleh diambil, disimpan, dan dioperasikan oleh karyawan yang namanya tercatat secara resmi pada sistem reservasi.',
        'Dilarang keras memindahtangankan kunci atau kendaraan kepada pihak lain tanpa persetujuan tertulis dari PIC Armada.',
      ],
    },
    {
      'number': '2',
      'category': 'operasional',
      'title': 'Penggunaan & Tujuan Kedinasan',
      'badge': 'OPERASIONAL',
      'badgeColor': const Color(0xFFBA0015),
      'items': [
        'Kendaraan dinas hanya diperuntukkan bagi keperluan tugas kedinasan dan operasional resmi PT Telkom Akses.',
        'Dilarang keras menyalahgunakan armada untuk kepentingan pribadi, liburan, atau aktivitas di luar penugasan dinas.',
        'Rute dan area perjalanan wajib bersesuaian dengan tujuan kedinasan yang telah diisi dan disetujui pada formulir pengajuan reservasi.',
      ],
    },
    {
      'number': '3',
      'category': 'gps',
      'title': 'Kewajiban Pengaktifan GPS & Telemetri Real-Time',
      'badge': 'WAJIB GPS AKTIF',
      'badgeColor': const Color(0xFFBB0016),
      'highlight': true,
      'items': [
        'Setiap peminjam WAJIB mengaktifkan layanan lokasi (Hardware GPS) smartphone dengan mode Akurasi Tinggi (High Accuracy) sebelum mengambil kunci dan selama seluruh masa dinas.',
        'Aplikasi monitoring secara otomatis memantau koordinat posisi, estimasi kecepatan berkendara, arah mata angin, serta jarak tempuh untuk memastikan keamanan perjalanan armada dinas.',
        'Izin lokasi pada smartphone harus disetel pada "Izinkan Sepanjang Waktu" atau "Saat Aplikasi Digunakan" dengan opsi Lokasi Tepat (Precise Location) aktif.',
        'Data telemetri digunakan oleh tim manajemen fleet untuk memastikan keselamatan pengemudi, pemantauan rute dinas, dan kesiapsiagaan bantuan darurat.',
      ],
    },
    {
      'number': '4',
      'category': 'gps',
      'title': 'Larangan Manipulasi Lokasi & Deteksi Fake GPS',
      'badge': 'KEAMANAN KETAT',
      'badgeColor': const Color(0xFFBB0016),
      'highlight': true,
      'items': [
        'DILARANG KERAS menggunakan aplikasi Fake GPS, Mock Location Provider, perangkat manipulasi rute, emulator, atau VPN lokasi tiruan.',
        'Sistem aplikasi dilengkapi proteksi anti-mock location dan algoritma deteksi lonjakan posisi tidak wajar (Impossible Jump / teleportasi koordinat).',
        'Apabila terdeteksi Fake GPS, proses peminjaman mobil maupun pengembalian kunci akan DIBLOKIR otomatis oleh sistem keamanan.',
        'Segala bentuk manipulasi koordinat lokasi dicatat pada log audit keamanan dan diklasifikasikan sebagai pelanggaran berat terhadap integritas kedinasan Telkom Akses.',
      ],
    },
    {
      'number': '5',
      'category': 'gps',
      'title': 'Larangan Mematikan GPS Selama Perjalanan Aktif',
      'badge': 'MONITORING AKTIF',
      'badgeColor': const Color(0xFFBB0016),
      'highlight': true,
      'items': [
        'Modul GPS perangkat dan koneksi internet dilarang dinonaktifkan selama peminjaman berada pada status "In Progress" (Sedang Digunakan).',
        'Jika GPS dimatikan atau izin dicabut di tengah perjalanan, aplikasi akan mengunci tampilan secara otomatis dan meminta pengaktifan ulang GPS sebelum fitur lain dapat diakses.',
        'Pemantauan telemetri GPS otomatis DIHENTIKAN tuntas begitu proses pengembalian kendaraan ("Completed") diselesaikan di loker pintar.',
      ],
    },
    {
      'number': '6',
      'category': 'operasional',
      'title': 'Pemeliharaan, BBM, & Kebersihan',
      'badge': 'PERAWATAN',
      'badgeColor': const Color(0xFF4B5563),
      'items': [
        'Peminjam wajib menjaga kebersihan interior maupun eksterior kendaraan selama dan sesudah masa peminjaman.',
        'Dilarang keras merokok, vape, atau mengonsumsi zat berbahaya di dalam kabin armada dinas.',
        'Level bahan bakar (BBM) saat pengembalian minimal harus setara dengan kondisi saat pengambilan awal armada.',
        'Segala indikasi kendala mekanis, lampu indikator mesin menyala, atau ban bocor wajib segera dilaporkan kepada PIC kendaraan.',
      ],
    },
    {
      'number': '7',
      'category': 'operasional',
      'title': 'Keselamatan, Batas Kecepatan, & Tilang',
      'badge': 'SAFETY FIRST',
      'badgeColor': const Color(0xFF4B5563),
      'items': [
        'Peminjam wajib mematuhi seluruh rambu dan peraturan perundang-undangan lalu lintas yang berlaku di Indonesia.',
        'Pengemudi wajib memperhatikan batas kecepatan aman jalan raya (terpantau melalui telemetri kecepatan GPS).',
        'Segala sanksi denda tilang konvensional maupun ETLE (Electronic Traffic Law Enforcement) yang terjadi selama masa peminjaman menjadi tanggung jawab penuh pengemudi.',
        'Perusahaan tidak bertanggung jawab atas kehilangan barang-barang pribadi yang tertinggal di dalam kabin mobil.',
      ],
    },
    {
      'number': '8',
      'category': 'pengembalian',
      'title': 'Prosedur Pengembalian & Loker Pintar',
      'badge': 'PENGEMBALIAN',
      'badgeColor': const Color(0xFF16A34A),
      'items': [
        'Armada harus dikembalikan tepat waktu sesuai jadwal estimasi yang disetujui demi menjaga ketersediaan jadwal staf lain.',
        'Pengembalian dilakukan dengan mengisi Form Pengembalian di aplikasi, mengunggah foto kondisi 4 sisi fisik mobil, dan mencatat kilometer akhir.',
        'Kunci wajib dimasukkan kembali ke slot loker pintar yang ditentukan, lalu pintu loker ditutup hingga terdeteksi terkunci sempurna pada sistem.',
      ],
    },
    {
      'number': '9',
      'category': 'umum',
      'title': 'Privasi & Perlindungan Data Karyawan',
      'badge': 'PRIVASI DATA',
      'badgeColor': const Color(0xFF374151),
      'items': [
        'Data koordinat GPS dan telemetri hanya direkam selama perjalanan kedinasan aktif dan disimpan secara aman pada server Telkom.',
        'Sistem tidak melakukan pelacakan lokasi pribadi saat karyawan tidak sedang dalam masa reservasi armada aktif.',
        'Data pemantauan digunakan semata-mata untuk audit efisiensi aset perusahaan, investigasi insiden darurat, dan jaminan keselamatan tim di lapangan.',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredSections = _sections.where((sec) {
      if (_selectedCategory == 'all') return true;
      if (_selectedCategory == 'gps') return sec['category'] == 'gps';
      if (_selectedCategory == 'operasional') return sec['category'] == 'operasional';
      if (_selectedCategory == 'pengembalian') return sec['category'] == 'pengembalian';
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Syarat & Ketentuan (SOP)',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER HERO CARD (Hitam - Merah Telkom Luxury Theme)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0A0A0A), // Hitam Pekat
                    Color(0xFF6B0007), // Deep Crimson
                    Color(0xFFBA0015), // Merah Telkom
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOP KENDARAAN DINAS TELKOM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Standar Operasional Prosedur Penggunaan Armada PT Telkom Akses',
                              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFFFDE047), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pembaruan Resmi: 9 Poin SOP Aman Berkendara & GPS Telemetri wajib dipatuhi.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // KATEGORI FILTER TABS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterTab('sop', '🛡️ SOP Aman Berkendara (9 Poin)'),
                  const SizedBox(width: 8),
                  _buildFilterTab('all', 'Semua Ketentuan'),
                  const SizedBox(width: 8),
                  _buildFilterTab('gps', '📍 Kebijakan GPS & Telemetri'),
                  const SizedBox(width: 8),
                  _buildFilterTab('operasional', '🚗 Operasional & Armada'),
                  const SizedBox(width: 8),
                  _buildFilterTab('pengembalian', '🔑 Loker & Pengembalian'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // TAMPILKAN 9 POIN SOP KETIKA TAB 'sop' ATAU 'all'
            if (_selectedCategory == 'sop' || _selectedCategory == 'all') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA0015),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '9 POIN RESMI AMAN BERKENDARA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA0015).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Branch Bogor',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBA0015),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // RENDER SEMUA 9 KARTU SOP
              ...kSopItems.map((sop) => _buildVisualSopCard(sop)),

              const SizedBox(height: 12),
            ],

            // LIST SECTION KETENTUAN UMUM / GPS / PENGEMBALIAN
            if (_selectedCategory != 'sop') ...[
              ...filteredSections.map((sec) {
                return _buildSectionCard(
                  number: sec['number'],
                  title: sec['title'],
                  badge: sec['badge'],
                  badgeColor: sec['badgeColor'],
                  isHighlight: sec['highlight'] == true,
                  items: List<String>.from(sec['items']),
                );
              }),
            ],

            const SizedBox(height: 14),

            // STATEMENT OF AGREEMENT
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFBA0015), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dengan melakukan permohonan reservasi peminjaman armada pada aplikasi ini, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan SOP operasional, 9 Poin Aman Berkendara, serta kepatuhan GPS telemetri di atas.',
                      style: TextStyle(
                        color: Color(0xFF7F1D1D),
                        fontSize: 11.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String key, String label) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBA0015) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFBA0015) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFBA0015).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  /// Desain Kartu Visual untuk 9 Poin SOP Berdasarkan Foto Infografis Resmi
  Widget _buildVisualSopCard(SopItem item) {
    final isDo = item.category == 'DO';
    final isDont = item.category == 'DONT';

    final Color badgeBg = isDo
        ? const Color(0xFFDCFCE7)
        : (isDont ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));

    final Color badgeText = isDo
        ? const Color(0xFF16A34A)
        : (isDont ? const Color(0xFFDC2626) : const Color(0xFFD97706));

    final IconData badgeIcon = isDo
        ? Icons.check_circle_rounded
        : (isDont ? Icons.cancel_rounded : Icons.info_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Garis Aksen Vertikal Kiri
              Container(
                width: 5,
                color: badgeText,
              ),

              // Gambar Poin SOP dari Infografis
              Container(
                width: 96,
                padding: const EdgeInsets.all(10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg.withValues(alpha: 0.35),
                ),
                child: Image.asset(
                  item.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    item.icon,
                    size: 40,
                    color: badgeText,
                  ),
                ),
              ),

              // Konten Teks & Penjelasan
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge Kategori (DO / DONT / TAMBAHAN)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, size: 11, color: badgeText),
                                const SizedBox(width: 4),
                                Text(
                                  item.categoryLabel,
                                  style: TextStyle(
                                    color: badgeText,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Poin ${item.id}/9',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Judul SOP
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Deskripsi SOP
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String badge,
    required Color badgeColor,
    required bool isHighlight,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
          width: isHighlight ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlight
                ? const Color(0xFFBA0015).withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris Angka, Judul & Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHighlight ? const Color(0xFFBA0015) : const Color(0xFF1F2937),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isHighlight ? const Color(0xFF991B1B) : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),

          // Daftar Poin-poin
          Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: isHighlight ? const Color(0xFFBA0015) : const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                          height: 1.45,
                        ),
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
