import 'dart:async';
import 'package:flutter/material.dart';

/// Model data untuk masing-masing poin SOP Aman Berkendara
class SopItem {
  final int id;
  final String number;
  final String category; // 'DO', 'DONT', 'TAMBAHAN'
  final String categoryLabel;
  final String title;
  final String description;
  final IconData icon;
  final String imageAsset;
  final Color primaryColor;
  final Color bgColor;
  final Color borderColor;
  final Color lightBg;

  const SopItem({
    required this.id,
    required this.number,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.description,
    required this.icon,
    required this.imageAsset,
    required this.primaryColor,
    required this.bgColor,
    required this.borderColor,
    required this.lightBg,
  });
}

/// Daftar resmi seluruh poin SOP Berdasarkan Infografis Telkom Akses Branch Bogor
const List<SopItem> kSopItems = [
  // --- YANG HARUS DILAKUKAN (DO's) ---
  SopItem(
    id: 1,
    number: '01',
    category: 'DO',
    categoryLabel: 'YANG HARUS DILAKUKAN (DO)',
    title: 'Kesadaran Penuh & Hati-Hati',
    description: 'Berkendara dengan fokus, waspada, dan berhati-hati selama menjalankan armada operasional.',
    icon: Icons.visibility_rounded,
    imageAsset: 'assets/images/sop/sop_1.png',
    primaryColor: Color(0xFF16A34A),
    bgColor: Color(0xFFF0FDF4),
    borderColor: Color(0xFFBBF7D0),
    lightBg: Color(0xFFDCFCE7),
  ),
  SopItem(
    id: 2,
    number: '02',
    category: 'DO',
    categoryLabel: 'YANG HARUS DILAKUKAN (DO)',
    title: 'Gunakan Jalur yang Layak',
    description: 'Pilih jalur yang aman dan muat untuk mobil, hindari memaksakan jalan sempit.',
    icon: Icons.add_road_rounded,
    imageAsset: 'assets/images/sop/sop_2.png',
    primaryColor: Color(0xFF16A34A),
    bgColor: Color(0xFFF0FDF4),
    borderColor: Color(0xFFBBF7D0),
    lightBg: Color(0xFFDCFCE7),
  ),
  SopItem(
    id: 3,
    number: '03',
    category: 'DO',
    categoryLabel: 'YANG HARUS DILAKUKAN (DO)',
    title: 'Pengecekan Kelengkapan',
    description: 'Pastikan membawa SIM A aktif, STNK, dan dokumen kendaraan lengkap sebelum jalan.',
    icon: Icons.badge_rounded,
    imageAsset: 'assets/images/sop/sop_3.png',
    primaryColor: Color(0xFF16A34A),
    bgColor: Color(0xFFF0FDF4),
    borderColor: Color(0xFFBBF7D0),
    lightBg: Color(0xFFDCFCE7),
  ),
  SopItem(
    id: 4,
    number: '04',
    category: 'DO',
    categoryLabel: 'YANG HARUS DILAKUKAN (DO)',
    title: 'Kondisi Fisik Prima',
    description: 'Istirahat yang cukup sebelum berkendara dan pastikan tubuh dalam keadaan sehat.',
    icon: Icons.health_and_safety_rounded,
    imageAsset: 'assets/images/sop/sop_4.png',
    primaryColor: Color(0xFF16A34A),
    bgColor: Color(0xFFF0FDF4),
    borderColor: Color(0xFFBBF7D0),
    lightBg: Color(0xFFDCFCE7),
  ),

  // --- YANG DILARANG (DONT's) ---
  SopItem(
    id: 5,
    number: '05',
    category: 'DONT',
    categoryLabel: 'YANG DILARANG (DON\'T)',
    title: 'Jangan Paksa Jalur Ekstrim / Rusak',
    description: 'Jangan memaksakan masuk ke jalur yang tidak mungkin dilewati roda empat (tidak boleh ke kebun/medan lumpur berat, menghindari mobil terperosok/diderek).',
    icon: Icons.warning_amber_rounded,
    imageAsset: 'assets/images/sop/sop_5.png',
    primaryColor: Color(0xFFDC2626),
    bgColor: Color(0xFFFEF2F2),
    borderColor: Color(0xFFFECACA),
    lightBg: Color(0xFFFEE2E2),
  ),
  SopItem(
    id: 6,
    number: '06',
    category: 'DONT',
    categoryLabel: 'YANG DILARANG (DON\'T)',
    title: 'Dilarang Serempetan / Maksa Jalan Sempit',
    description: 'Hindari jalan sempit yang berisiko membuat bodi mobil lecet, baret, atau terserempet.',
    icon: Icons.minor_crash_rounded,
    imageAsset: 'assets/images/sop/sop_6.png',
    primaryColor: Color(0xFFDC2626),
    bgColor: Color(0xFFFEF2F2),
    borderColor: Color(0xFFFECACA),
    lightBg: Color(0xFFFEE2E2),
  ),
  SopItem(
    id: 7,
    number: '07',
    category: 'DONT',
    categoryLabel: 'YANG DILARANG (DON\'T)',
    title: 'Dilarang di Bawah Pengaruh Alkohol / Obat',
    description: 'Jangan mengemudi setelah minum alkohol atau saat mengonsumsi obat yang bikin kantuk.',
    icon: Icons.no_drinks_rounded,
    imageAsset: 'assets/images/sop/sop_7.png',
    primaryColor: Color(0xFFDC2626),
    bgColor: Color(0xFFFEF2F2),
    borderColor: Color(0xFFFECACA),
    lightBg: Color(0xFFFEE2E2),
  ),
  SopItem(
    id: 8,
    number: '08',
    category: 'DONT',
    categoryLabel: 'YANG DILARANG (DON\'T)',
    title: 'Hindari Mengemudi Saat Mengantuk',
    description: 'Jika lelah atau mengantuk, segera berhenti dan istirahat sejenak, jangan dipaksakan.',
    icon: Icons.bedtime_rounded,
    imageAsset: 'assets/images/sop/sop_8.png',
    primaryColor: Color(0xFFDC2626),
    bgColor: Color(0xFFFEF2F2),
    borderColor: Color(0xFFFECACA),
    lightBg: Color(0xFFFEE2E2),
  ),

  // --- SOP TAMBAHAN ---
  SopItem(
    id: 9,
    number: '09',
    category: 'TAMBAHAN',
    categoryLabel: 'SOP TAMBAHAN KESELAMATAN',
    title: 'Sabuk Pengaman & Batas Kecepatan',
    description: 'Gunakan sabuk pengaman selalu, patuhi batas kecepatan, dan laporkan setiap insiden/kerusakan secepatnya kepada PIC.',
    icon: Icons.airline_seat_legroom_extra_rounded,
    imageAsset: 'assets/images/sop/sop_9.png',
    primaryColor: Color(0xFFD97706),
    bgColor: Color(0xFFFFFBEB),
    borderColor: Color(0xFFFDE68A),
    lightBg: Color(0xFFFEF3C7),
  ),
];

/// Widget Carousel Banner SOP yang berganti otomatis secara periodik
/// dengan indikator detik dan tipografi yang sangat jelas & terbaca.
class SopCarouselBanner extends StatefulWidget {
  const SopCarouselBanner({super.key});

  @override
  State<SopCarouselBanner> createState() => _SopCarouselBannerState();
}

class _SopCarouselBannerState extends State<SopCarouselBanner> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _rotationTimer;
  Timer? _secondProgressTimer;

  // Interval rotasi: 4 detik per poin (nyaman dibaca secara visual)
  static const int _slideIntervalSeconds = 4;
  int _secondsRemaining = _slideIntervalSeconds;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimers();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _secondProgressTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimers() {
    _rotationTimer?.cancel();
    _secondProgressTimer?.cancel();

    _secondsRemaining = _slideIntervalSeconds;

    // Timer per 1 detik untuk menghitung mundur & progress bar
    _secondProgressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;

      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = _slideIntervalSeconds;
          _goToNextPage();
        }
      });
    });
  }

  void _goToNextPage() {
    if (!_pageController.hasClients) return;
    final nextIndex = (_currentIndex + 1) % kSopItems.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goToPreviousPage() {
    if (!_pageController.hasClients) return;
    final prevIndex = (_currentIndex - 1 + kSopItems.length) % kSopItems.length;
    _pageController.animateToPage(
      prevIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    setState(() {
      _secondsRemaining = _slideIntervalSeconds;
    });
  }

  void _onUserTouchDown() {
    if (!_isPaused) {
      setState(() => _isPaused = true);
    }
  }

  void _onUserTouchUp() {
    if (_isPaused) {
      setState(() {
        _isPaused = false;
        _secondsRemaining = _slideIntervalSeconds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section SOP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFECEF), Color(0xFFFFD9DF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOP AMAN BERKENDARA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Semua Armada • Telkom Akses',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showAllSopModal(context),
              icon: const Icon(Icons.list_alt_rounded, size: 14, color: Color(0xFFBA0015)),
              label: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBA0015),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Carousel Card Container
        GestureDetector(
          onTapDown: (_) => _onUserTouchDown(),
          onTapUp: (_) => _onUserTouchUp(),
          onTapCancel: () => _onUserTouchUp(),
          onTap: () => _showAllSopModal(context),
          child: SizedBox(
            height: 168,
            child: PageView.builder(
              controller: _pageController,
              itemCount: kSopItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _secondsRemaining = _slideIntervalSeconds;
                });
              },
              itemBuilder: (context, index) {
                final item = kSopItems[index];
                return _buildSopCard(item);
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Bottom Controls: Indicators & Next/Prev (tanpa tulisan detik)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Indikator Titik Poin
            Row(
              children: List.generate(kSopItems.length, (index) {
                final isCurrent = index == _currentIndex;
                final item = kSopItems[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: isCurrent ? 18 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? item.primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            // Tombol Navigasi Arah
            Row(
              children: [
                InkWell(
                  onTap: _goToPreviousPage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFF4B5563)),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _goToNextPage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Desain Kartu SOP dengan gradasi lembut, tanpa garis (borderless), dan foto resmi dari infografis
  Widget _buildSopCard(SopItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.category == 'DO'
              ? [
                  Colors.white,
                  const Color(0xFFF2FBF5),
                  const Color(0xFFE2F9EB),
                ]
              : item.category == 'DONT'
                  ? [
                      Colors.white,
                      const Color(0xFFFFF4F4),
                      const Color(0xFFFFE7E7),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFFFFDF5),
                      const Color(0xFFFEF3C7),
                    ],
        ),
        boxShadow: [
          BoxShadow(
            color: item.primaryColor.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Badge Kategori & Poin Counter (tanpa garis)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.lightBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.category == 'DO'
                          ? Icons.check_circle_rounded
                          : item.category == 'DONT'
                              ? Icons.cancel_rounded
                              : Icons.info_rounded,
                      size: 13,
                      color: item.primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.categoryLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: item.primaryColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Poin ${item.id} / ${kSopItems.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content Row: Photo & Text (Title + Description)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Box Foto Ilustrasi Infografis - Tanpa garis, bergradasi cantik
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item.category == 'DO'
                          ? [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)]
                          : item.category == 'DONT'
                              ? [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]
                              : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    item.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      item.icon,
                      color: item.primaryColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Text: Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

  /// Menampilkan BottomSheet Rinci Semua Poin SOP
  void _showAllSopModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AllSopBottomSheet(),
    );
  }
}

/// Modal Lembar Bawah untuk membaca keseluruhan SOP Poin per Poin secara detail
class _AllSopBottomSheet extends StatefulWidget {
  const _AllSopBottomSheet();

  @override
  State<_AllSopBottomSheet> createState() => _AllSopBottomSheetState();
}

class _AllSopBottomSheetState extends State<_AllSopBottomSheet> {
  String _filter = 'ALL'; // 'ALL', 'DO', 'DONT', 'TAMBAHAN'

  @override
  Widget build(BuildContext context) {
    final filteredList = kSopItems.where((item) {
      if (_filter == 'ALL') return true;
      return item.category == _filter;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFECEF), Color(0xFFFFD9DF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset('assets/images/app_icon.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOP & Cara Aman Berkendara',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          ),
                          Text(
                            'Operasional Semua Armada • Telkom Akses',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 20),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('ALL', 'Semua (${kSopItems.length})', const Color(0xFFBA0015)),
                      const SizedBox(width: 8),
                      _buildChip('DO', 'Yang Harus Dilakukan (4)', const Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      _buildChip('DONT', 'Yang Dilarang (4)', const Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      _buildChip('TAMBAHAN', 'SOP Tambahan (1)', const Color(0xFFD97706)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Reminder Banner dari Infografis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.campaign_rounded, color: Color(0xFF1D4ED8), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'ARMADA ADALAH ASET KERJA, JAGA & GUNAKAN DENGAN BIJAK!',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Banyak insiden serempetan, lecet, bahkan mobil terperosok hingga harus diderek karena memaksakan jalur yang tidak layak. Mari saling menjaga keselamatan dan armada kita.',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF1E40AF), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // List of points
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: filteredList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            item.bgColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: item.primaryColor.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: item.category == 'DO'
                                    ? [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)]
                                    : item.category == 'DONT'
                                        ? [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]
                                        : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              item.imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(item.icon, color: item.primaryColor, size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.lightBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.categoryLabel,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: item.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '#${item.number}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Slogan Branch Bogor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFFBB0016),
                child: const Column(
                  children: [
                    Text(
                      '“UTAMAKAN KESELAMATAN, JAGA ARMADA KITA!”',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Melanggar SOP dapat dikenakan sanksi operasional. • BRANCH BOGOR',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String key, String label, Color color) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = key),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF4B5563),
      ),
      selectedColor: color,
      backgroundColor: Colors.grey.shade100,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
      ),
    );
  }
}
