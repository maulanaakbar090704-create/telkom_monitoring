import 'package:flutter/material.dart';
import '../utils/gps_requirement_manager.dart';
import '../screens/common/gps_required_screen.dart';

/// Guard terpusat yang memverifikasi prasyarat wajib aplikasi Peminjam:
/// Layanan Lokasi / GPS Aktif
class AppRequirementGuard extends StatelessWidget {
  final Widget child;

  const AppRequirementGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GpsRequirementManager.instance.isGpsReadyNotifier,
      builder: (context, isGpsReady, _) {
        Widget currentScreen;

        // Jika GPS mati atau izin ditolak -> Layar GPS Wajib Aktif
        if (!isGpsReady) {
          currentScreen = const GpsRequiredScreen(key: ValueKey('gps_required_screen'));
        }
        // Normal: Tampilkan konten aplikasi
        else {
          currentScreen = KeyedSubtree(
            key: const ValueKey('normal_app_content'),
            child: child,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: currentScreen,
        );
      },
    );
  }
}
