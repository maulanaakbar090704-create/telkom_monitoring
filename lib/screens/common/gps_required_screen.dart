import 'package:flutter/material.dart';
import '../../utils/gps_requirement_manager.dart';

/// Layar penahan ketika layanan lokasi / GPS perangkat Peminjam tidak aktif
class GpsRequiredScreen extends StatefulWidget {
  const GpsRequiredScreen({super.key});

  @override
  State<GpsRequiredScreen> createState() => _GpsRequiredScreenState();
}

class _GpsRequiredScreenState extends State<GpsRequiredScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _radarScale;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _radarScale = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
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
                // Ilustrasi Pin Lokasi & Radar Berdenyut
                ScaleTransition(
                  scale: _radarScale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_off_rounded,
                      color: Color(0xFFD97706),
                      size: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Judul Peringatan
                const Text(
                  'GPS Wajib Diaktifkan',
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
                  'Sebagai peminjam kendaraan dinas Telkom, Anda wajib mengaktifkan GPS perangkat untuk memastikan keamanan armada & akurasi telemetri perjalanan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Kartu Status & Ketentuan
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
                  child: ValueListenableBuilder<GpsRequirementStatus>(
                    valueListenable: GpsRequirementManager.instance.statusNotifier,
                    builder: (context, status, _) {
                      String statusDesc;
                      IconData statusIcon;
                      Color statusColor;

                      if (status == GpsRequirementStatus.serviceDisabled) {
                        statusDesc = 'Layanan Lokasi (GPS) pada perangkat Anda saat ini nonaktif.';
                        statusIcon = Icons.gps_off_rounded;
                        statusColor = const Color(0xFFDC2626);
                      } else if (status == GpsRequirementStatus.permissionDenied) {
                        statusDesc = 'Izin lokasi belum diberikan kepada aplikasi peminjam.';
                        statusIcon = Icons.security_rounded;
                        statusColor = const Color(0xFFD97706);
                      } else if (status == GpsRequirementStatus.permissionPermanentlyDenied) {
                        statusDesc = 'Izin lokasi ditolak permanen. Buka pengaturan izin aplikasi.';
                        statusIcon = Icons.settings_suggest_rounded;
                        statusColor = const Color(0xFFDC2626);
                      } else {
                        statusDesc = 'Layanan GPS aktif & terverifikasi.';
                        statusIcon = Icons.gps_fixed_rounded;
                        statusColor = const Color(0xFF16A34A);
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(statusIcon, color: statusColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  statusDesc,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: Color(0xFFF3F4F6)),
                          _buildRequirementItem(
                            Icons.check_circle_rounded,
                            'Kepatuhan SOP monitoring perjalanan kendaraan Telkom',
                          ),
                          const SizedBox(height: 8),
                          _buildRequirementItem(
                            Icons.check_circle_rounded,
                            'Koneksi live telemetry armada ke tim Admin & PIC',
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Tombol Buka Pengaturan Lokasi
                ValueListenableBuilder<bool>(
                  valueListenable: GpsRequirementManager.instance.isCheckingNotifier,
                  builder: (context, isChecking, _) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final status = GpsRequirementManager.instance.statusNotifier.value;
                              if (status == GpsRequirementStatus.permissionPermanentlyDenied) {
                                await GpsRequirementManager.instance.openAppSettings();
                              } else {
                                await GpsRequirementManager.instance.openLocationSettings();
                              }
                              // Periksa ulang setelah kembali
                              await Future.delayed(const Duration(milliseconds: 500));
                              await GpsRequirementManager.instance.checkGpsStatus(requestPermissionIfNeeded: true);
                            },
                            icon: const Icon(Icons.settings_rounded, color: Colors.white),
                            label: const Text(
                              'BUKA PENGATURAN GPS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBB0016),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: isChecking
                                ? null
                                : () async {
                                    final isReady = await GpsRequirementManager.instance.checkGpsStatus(
                                      requestPermissionIfNeeded: true,
                                    );
                                    if (!context.mounted) return;
                                    if (!isReady) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Layanan GPS masih belum aktif. Aktifkan lokasi di HP.'),
                                          backgroundColor: Color(0xFFDC2626),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                            icon: isChecking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFBB0016),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, color: Color(0xFFBB0016)),
                            label: Text(
                              isChecking ? 'Memeriksa GPS...' : 'Periksa Ulang GPS',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFBB0016),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFBB0016), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildRequirementItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4B5563),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
