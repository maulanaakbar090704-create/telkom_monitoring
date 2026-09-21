import 'package:flutter/material.dart';
import '../return/return_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search query
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController);
    _loadHistoryData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User tidak ditemukan");

      final response = await Supabase.instance.client
          .from('bookings')
          .select('*, vehicles(make_model, registration_no, pic_name, pic_nik)')
          .eq('employee_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _historyList = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final DateTime parsed = DateTime.parse(rawDate).toLocal();
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final day = parsed.day.toString().padLeft(2, '0');
      final month = monthNames[parsed.month - 1];
      final year = parsed.year;
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return "$day $month $year, $hour:$minute";
    } catch (e) {
      return rawDate;
    }
  }

  // Dialog Detail Peminjaman Lengkap
  void _showBookingDetailModal(Map<String, dynamic> item) {
    final vehicle = item['vehicles'] ?? {};
    final carName = vehicle['make_model'] ?? 'Mobil Kantor';
    final plateNumber = vehicle['registration_no'] ?? item['plat_nomor'] ?? '-';
    final status = item['status'];
    final destination = item['destination'] ?? '-';
    final purpose = item['purpose'] ?? '-';
    final startAt = _formatDate(item['start_at']);
    final returnedAt = _formatDate(item['returned_at']);
    final picName = vehicle['pic_name']?.toString() ?? 'PIC Kantor';
    final picNik = vehicle['pic_nik']?.toString() ?? '-';
    final adminNote = item['admin_note'];
    final qrCode = item['qr_locker_code'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                            ),
                            const SizedBox(height: 6),
                            _buildIndonesianPlateBadge(plateNumber),
                          ],
                        ),
                      ),
                      _buildStatusTag(status),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Data Rincian Peminjaman
                  _buildDetailRow(Icons.place_outlined, 'Tujuan Perjalanan', destination),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.work_outline_rounded, 'Keperluan Operasional', purpose),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.access_time_rounded, 'Waktu Mulai Pinjam', startAt),
                  if (status == 'completed') ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.task_alt_rounded, 'Waktu Pengembalian', returnedAt),
                  ],
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.person_pin_outlined, 'Penanggung Jawab (PIC)', '$picName (NIK: $picNik)'),

                  if (qrCode != null && qrCode.toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, color: Color(0xFF1D4ED8), size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kode Loker Kunci Pintar:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                                const SizedBox(height: 2),
                                Text(qrCode.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 1.0)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (adminNote != null && adminNote.toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.speaker_notes_outlined, color: Color(0xFFD97706), size: 16),
                              SizedBox(width: 6),
                              Text('Catatan Admin / Pengelola:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(adminNote.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (status == 'active') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReturnScreen(
                                bookingId: item['id']?.toString(),
                                initialBooking: item,
                              ),
                            ),
                          );
                          _loadHistoryData();
                        },
                        icon: const Icon(Icons.assignment_return_outlined, color: Colors.white, size: 18),
                        label: const Text('Proses Pengembalian Mobil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBB0016),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tutup', style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F3567)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTag(String? status) {
    if (status == 'active') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
        child: const Text('DIGUNAKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
      );
    } else if (status == 'pending' || status == 'pending_admin') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
        child: const Text('MENUNGGU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
        child: const Text('SELESAI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter berdasarkan query pencarian
    final filteredList = _historyList.where((item) {
      final vehicle = item['vehicles'] ?? {};
      final car = (vehicle['make_model'] ?? '').toString().toLowerCase();
      final plate = (vehicle['registration_no'] ?? item['plat_nomor'] ?? '').toString().toLowerCase();
      final dest = (item['destination'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase().trim();

      return q.isEmpty || car.contains(q) || plate.contains(q) || dest.contains(q);
    }).toList();

    final allList = filteredList;
    final pendingList = filteredList.where((item) => item['status'] == 'pending_admin' || item['status'] == 'pending').toList();
    final activeList = filteredList.where((item) => item['status'] == 'active').toList();
    final completedList = filteredList.where((item) => item['status'] == 'completed').toList();

    return DefaultTabController(
      length: 4, // 4 Tab: SEMUA, MENUNGGU, DIGUNAKAN, SELESAI
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Stack(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F3567), Color(0xFF8B1229), Color(0xFFBB0016)],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Riwayat Peminjaman',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Log aktivitas & bukti peminjaman armada Anda',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _loadHistoryData,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                          tooltip: 'Segarkan Riwayat',
                        ),
                      ],
                    ),
                  ),

                  // Search Bar Riwayat
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Cari mobil, plat nomor, atau tujuan...',
                          hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TAB BAR RESPONSIVE 4 TAB
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicator: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: const Color(0xFFBB0016),
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      tabs: [
                        Tab(text: 'SEMUA (${allList.length})'),
                        Tab(text: 'MENUNGGU (${pendingList.length})'),
                        Tab(text: 'AKTIF (${activeList.length})'),
                        Tab(text: 'SELESAI (${completedList.length})'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TAB BAR VIEW
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : _errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.white, size: 40),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Gagal memuat: $_errorMessage',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _loadHistoryData,
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                                        child: const Text('Coba Lagi', style: TextStyle(color: Color(0xFFBB0016))),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : TabBarView(
                                children: [
                                  _buildTabContent(allList, 'Belum ada catatan riwayat peminjaman.'),
                                  _buildTabContent(pendingList, 'Tidak ada pengajuan yang sedang menunggu persetujuan.'),
                                  _buildTabContent(activeList, 'Tidak ada kendaraan yang sedang Anda gunakan saat ini.'),
                                  _buildTabContent(completedList, 'Belum ada riwayat peminjaman yang telah selesai.'),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<Map<String, dynamic>> listData, String emptyMsg) {
    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      color: const Color(0xFFBB0016),
      child: listData.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 80),
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 14),
                Text(
                  _searchQuery.isNotEmpty ? 'Tidak ada hasil untuk "$_searchQuery"' : emptyMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              itemCount: listData.length,
              itemBuilder: (context, index) {
                final item = listData[index];
                final status = item['status'];
                final vehicle = item['vehicles'] ?? {};
                final carName = vehicle['make_model'] ?? 'Mobil Operasional';
                final plateNumber = vehicle['registration_no'] ?? item['plat_nomor'] ?? '-';
                final destination = item['destination'] ?? '-';
                final formattedDate = _formatDate(item['start_at']);
                final adminNote = item['admin_note'];
                final picName = vehicle['pic_name']?.toString() ?? 'PIC Kantor';
                final picNik = vehicle['pic_nik']?.toString() ?? '-';

                if (status == 'pending_admin' || status == 'pending') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildPendingLoanCard(
                      item: item,
                      carName: carName,
                      plateNumber: plateNumber,
                      date: formattedDate,
                      destination: destination,
                      picName: picName,
                      picNik: picNik,
                    ),
                  );
                } else if (status == 'active') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildActiveLoanCard(
                      item: item,
                      carName: carName,
                      plateNumber: plateNumber,
                      date: formattedDate,
                      destination: destination,
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildCompletedLoanCard(
                      item: item,
                      carName: carName,
                      plateNumber: plateNumber,
                      date: formattedDate,
                      destination: destination,
                      adminNote: adminNote,
                    ),
                  );
                }
              },
            ),
    );
  }

  // --- KARTU PENDING ---
  Widget _buildPendingLoanCard({
    required Map<String, dynamic> item,
    required String carName,
    required String plateNumber,
    required String date,
    required String destination,
    required String picName,
    required String picNik,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: _pulseAnimation,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'MENUNGGU PERSETUJUAN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                onPressed: () => _showBookingDetailModal(item),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(carName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildIndonesianPlateBadge(plateNumber),
              const SizedBox(width: 10),
              const Icon(Icons.access_time, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tujuan Dinas', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(destination, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_pin_circle_outlined, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PIC: $picName (NIK: $picNik)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF78350F)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- KARTU AKTIF (SEDANG DIGUNAKAN) ---
  Widget _buildActiveLoanCard({
    required Map<String, dynamic> item,
    required String carName,
    required String plateNumber,
    required String date,
    required String destination,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        border: Border.all(color: Colors.green.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: _pulseAnimation,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('SEDANG DIGUNAKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.info_outline, color: Color(0xFF16A34A), size: 20),
                onPressed: () => _showBookingDetailModal(item),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(carName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildIndonesianPlateBadge(plateNumber),
              const SizedBox(width: 10),
              const Icon(Icons.access_time, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tujuan', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(destination, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReturnScreen(
                      bookingId: item['id']?.toString(),
                      initialBooking: item,
                    ),
                  ),
                );
                _loadHistoryData();
              },
              icon: const Icon(Icons.assignment_return_outlined, size: 16, color: Colors.white),
              label: const Text('Kembalikan Mobil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB0016),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- KARTU SELESAI ---
  Widget _buildCompletedLoanCard({
    required Map<String, dynamic> item,
    required String carName,
    required String plateNumber,
    required String date,
    required String destination,
    String? adminNote,
  }) {
    return InkWell(
      onTap: () => _showBookingDetailModal(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF6B7280)),
                      SizedBox(width: 4),
                      Text('SELESAI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(carName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildIndonesianPlateBadge(plateNumber),
                const SizedBox(width: 10),
                const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tujuan:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(destination, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
              ],
            ),
            if (adminNote != null && adminNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        adminNote,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Plat Nomor Khas Indonesia
  Widget _buildIndonesianPlateBadge(String plateNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF94A3B8), width: 0.8),
      ),
      child: Text(
        plateNumber.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}