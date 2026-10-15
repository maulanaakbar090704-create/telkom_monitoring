import 'package:flutter/material.dart';
import '../../utils/network_manager.dart';

/// Layar penahan ketika koneksi internet / data seluler mati
class NoNetworkScreen extends StatefulWidget {
  const NoNetworkScreen({super.key});

  @override
  State<NoNetworkScreen> createState() => _NoNetworkScreenState();
}

class _NoNetworkScreenState extends State<NoNetworkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ilustrasi Icon Radar Jaringan Berdenyut
                ScaleTransition(
                  scale: _pulseScale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: Color(0xFFDC2626),
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Judul Peringatan
                const Text(
                  'Tidak Ada Jaringan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Penjelasan
                const Text(
                  'Aplikasi Peminjaman Mobil memerlukan koneksi internet aktif untuk sinkronisasi pemesanan & telemetri GPS armada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Kartu Petunjuk Pengaktifan Jaringan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      _buildChecklistRow(
                        Icons.signal_cellular_alt_rounded,
                        'Pastikan Data Seluler atau Wi-Fi telah aktif',
                      ),
                      const Divider(height: 18, color: Color(0xFFF3F4F6)),
                      _buildChecklistRow(
                        Icons.airplanemode_inactive_rounded,
                        'Nonaktifkan Mode Pesawat (Airplane Mode)',
                      ),
                      const Divider(height: 18, color: Color(0xFFF3F4F6)),
                      _buildChecklistRow(
                        Icons.lock_clock_rounded,
                        'Periksa kembali kuota paket data internet Anda',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Tombol Coba Hubungkan Kembali
                ValueListenableBuilder<bool>(
                  valueListenable: NetworkManager.instance.isCheckingNotifier,
                  builder: (context, isChecking, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isChecking
                            ? null
                            : () async {
                                final hasNet = await NetworkManager.instance.checkConnection();
                                if (!context.mounted) return;
                                if (!hasNet) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Jaringan masih belum tersedia. Periksa koneksi HP Anda.'),
                                      backgroundColor: Color(0xFFDC2626),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                        icon: isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, color: Colors.white),
                        label: Text(
                          isChecking ? 'Memeriksa Sinyal...' : 'Coba Hubungkan Kembali',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBB0016),
                          disabledBackgroundColor: const Color(0xFFF87171),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistRow(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF374151)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}
