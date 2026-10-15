import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Status izin dan layanan GPS perangkat Peminjam
enum GpsRequirementStatus {
  serviceDisabled, // Layanan lokasi di HP dimatikan
  permissionDenied, // Izin lokasi ditolak
  permissionPermanentlyDenied, // Izin ditolak permanen
  ready, // Layanan aktif & izin diberikan
}

/// Manager kewajiban pengaktifan GPS untuk aplikasi Peminjam
class GpsRequirementManager {
  GpsRequirementManager._();
  static final GpsRequirementManager instance = GpsRequirementManager._();

  final ValueNotifier<bool> isGpsReadyNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<GpsRequirementStatus> statusNotifier =
      ValueNotifier<GpsRequirementStatus>(GpsRequirementStatus.ready);
  final ValueNotifier<bool> isCheckingNotifier = ValueNotifier<bool>(false);

  Timer? _periodicTimer;

  bool get isGpsReady => isGpsReadyNotifier.value;

  /// Inisialisasi pendengar status GPS
  Future<void> init() async {
    await checkGpsStatus();

    // Pengecekan berkala status GPS setiap 4 detik (misal user menyalakan GPS lewat Quick Settings Android)
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      checkGpsStatus(isSilent: true);
    });
  }

  /// Memeriksa apakah layanan GPS aktif dan izin telah diberikan
  Future<bool> checkGpsStatus({bool isSilent = false, bool requestPermissionIfNeeded = false}) async {
    if (!isSilent) {
      isCheckingNotifier.value = true;
    }

    bool isReady = false;
    GpsRequirementStatus currentStatus = GpsRequirementStatus.serviceDisabled;

    try {
      // 1. Cek apakah hardware layanan GPS di HP dinyalakan
      final bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        currentStatus = GpsRequirementStatus.serviceDisabled;
        isReady = false;
      } else {
        // 2. Cek izin lokasi aplikasi
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied && requestPermissionIfNeeded) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied) {
          currentStatus = GpsRequirementStatus.permissionDenied;
          isReady = false;
        } else if (permission == LocationPermission.deniedForever) {
          currentStatus = GpsRequirementStatus.permissionPermanentlyDenied;
          isReady = false;
        } else {
          currentStatus = GpsRequirementStatus.ready;
          isReady = true;
        }
      }
    } catch (_) {
      isReady = false;
      currentStatus = GpsRequirementStatus.serviceDisabled;
    } finally {
      statusNotifier.value = currentStatus;
      isGpsReadyNotifier.value = isReady;
      if (!isSilent) {
        isCheckingNotifier.value = false;
      }
    }

    return isReady;
  }

  /// Membuka langsung halaman Pengaturan Lokasi perangkat (GPS toggle)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Membuka pengaturan izin aplikasi
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  void dispose() {
    _periodicTimer?.cancel();
  }
}
