import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/direction_helper.dart';
import '../utils/security_manager.dart';

enum GpsSecurityStatus {
  ready,
  disabled,
  permissionDenied,
  mockDetected,
}

enum GpsSyncStatus {
  idle,
  syncing,
  success,
  mockBlocked,
  error,
}

/// Model state telemetri pelacakan GPS secara real-time
class GpsTrackingData {
  final bool isTracking;
  final String? bookingId;
  final Position? lastPosition;
  final double speedKmh;
  final double totalDistanceKm;
  final double? heading;
  final String? headingCardinal;
  final DateTime? lastUpdateTime;
  final GpsSyncStatus syncStatus;
  final String? errorMessage;
  final int updateCount;

  const GpsTrackingData({
    this.isTracking = false,
    this.bookingId,
    this.lastPosition,
    this.speedKmh = 0.0,
    this.totalDistanceKm = 0.0,
    this.heading,
    this.headingCardinal,
    this.lastUpdateTime,
    this.syncStatus = GpsSyncStatus.idle,
    this.errorMessage,
    this.updateCount = 0,
  });

  GpsTrackingData copyWith({
    bool? isTracking,
    String? bookingId,
    Position? lastPosition,
    double? speedKmh,
    double? totalDistanceKm,
    double? heading,
    String? headingCardinal,
    DateTime? lastUpdateTime,
    GpsSyncStatus? syncStatus,
    String? errorMessage,
    int? updateCount,
  }) {
    return GpsTrackingData(
      isTracking: isTracking ?? this.isTracking,
      bookingId: bookingId ?? this.bookingId,
      lastPosition: lastPosition ?? this.lastPosition,
      speedKmh: speedKmh ?? this.speedKmh,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      heading: heading ?? this.heading,
      headingCardinal: headingCardinal ?? this.headingCardinal,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      updateCount: updateCount ?? this.updateCount,
    );
  }
}

class GpsService {
  GpsService._internal();
  static final GpsService instance = GpsService._internal();

  // --- State Pelacakan Periodik 5 Detik ---
  Timer? _periodicTimer;
  String? _activeBookingId;
  bool _isSyncing = false;
  Position? _previousPosition;
  DateTime? _previousPositionTime;
  double? _lastKnownHeading;
  double _accumulatedDistanceKm = 0.0;
  int _updateCounter = 0;

  /// Notifier status & telemetri pelacakan untuk pembaruan UI otomatis
  final ValueNotifier<GpsTrackingData> trackingNotifier =
      ValueNotifier<GpsTrackingData>(const GpsTrackingData());

  /// Apakah proses pengiriman periodik 5 detik sedang berjalan aktif
  bool get isPeriodicTrackingActive =>
      _periodicTimer != null && _periodicTimer!.isActive;

  /// ID booking yang saat ini sedang dilacak
  String? get activeBookingId => _activeBookingId;

  /// Memeriksa apakah Layanan Lokasi (Hardware GPS) aktif di perangkat
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Memeriksa status izin lokasi saat ini
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Meminta izin lokasi ke pengguna
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Memeriksa status keamanan GPS lengkap termasuk deteksi Fake GPS (Mock Location)
  Future<GpsSecurityStatus> checkGpsSecurity() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) return GpsSecurityStatus.disabled;

      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return GpsSecurityStatus.permissionDenied;
      }

      // Deteksi manipulasi lokasi (Fake GPS / Mock Location provider)
      final position = await getCurrentPosition();
      if (position != null && position.isMocked) {
        debugPrint('⚠️ SECURITY BREACH: Terdeteksi Fake GPS / Mock Location!');
        return GpsSecurityStatus.mockDetected;
      }

      return GpsSecurityStatus.ready;
    } catch (e) {
      debugPrint('Error checking GPS security: $e');
      return GpsSecurityStatus.disabled;
    }
  }

  /// Memeriksa apakah GPS benar-benar siap, diizinkan, dan asli (bukan Fake GPS)
  Future<bool> isGpsReady() async {
    final status = await checkGpsSecurity();
    return status == GpsSecurityStatus.ready;
  }

  /// Cek cepat apakah Fake GPS sedang aktif
  Future<bool> isMockLocation() async {
    try {
      final position = await getCurrentPosition();
      return position?.isMocked ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Membuka langsung halaman Pengaturan Lokasi / GPS di HP (Android / iOS)
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
      return false;
    }
  }

  /// Membuka Pengaturan Izin Aplikasi di HP jika izin ditolak permanen
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Mendengarkan perubahan status hardware GPS secara live (Enabled / Disabled)
  Stream<ServiceStatus>? getServiceStatusStream() {
    try {
      return Geolocator.getServiceStatusStream();
    } catch (e) {
      debugPrint('Error getting service status stream: $e');
      return null;
    }
  }

  /// Mengambil koordinat pengguna saat ini dengan akurasi tinggi
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  // =========================================================================
  // LOGIKA PENGIRIMAN KOORDINAT GPS BERKALA SETIAP 5 DETIK KE SUPABASE
  // =========================================================================

  /// Memulai pengiriman titik koordinat GPS ke tabel `bookings` di Supabase setiap 5 detik
  void startPeriodicTracking({required String bookingId}) {
    if (bookingId.isEmpty) return;

    if (isPeriodicTrackingActive && _activeBookingId == bookingId) {
      return;
    }

    stopPeriodicTracking();

    _activeBookingId = bookingId;
    _previousPosition = null;
    _previousPositionTime = null;
    _lastKnownHeading = null;
    _accumulatedDistanceKm = 0.0;
    _updateCounter = 0;

    trackingNotifier.value = GpsTrackingData(
      isTracking: true,
      bookingId: bookingId,
      syncStatus: GpsSyncStatus.syncing,
    );

    debugPrint('🚀 [GPS Tracker] Memulai pengiriman koordinat GPS ke Supabase setiap 5 detik untuk Booking ID: $bookingId');

    _sendTrackingUpdate();

    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendTrackingUpdate();
    });
  }

  /// Menghentikan proses pengiriman koordinat periodik
  void stopPeriodicTracking() {
    if (_periodicTimer != null) {
      _periodicTimer!.cancel();
      _periodicTimer = null;
    }
    _activeBookingId = null;
    _isSyncing = false;

    trackingNotifier.value = trackingNotifier.value.copyWith(
      isTracking: false,
      syncStatus: GpsSyncStatus.idle,
    );

    debugPrint('🛑 [GPS Tracker] Pengiriman koordinat periodik ke Supabase dihentikan.');
  }

  /// Prosedur internal pengiriman koordinat ke Supabase
  Future<void> _sendTrackingUpdate() async {
    final bookingId = _activeBookingId;
    if (bookingId == null || _isSyncing) return;

    _isSyncing = true;
    try {
      // A. Cek integritas GPS (Deteksi Mock / Fake GPS)
      final secStatus = await checkGpsSecurity();
      if (secStatus == GpsSecurityStatus.mockDetected) {
        debugPrint('⚠️ [GPS Tracker] Fake GPS terdeteksi! Pengiriman koordinat diblokir.');
        trackingNotifier.value = trackingNotifier.value.copyWith(
          syncStatus: GpsSyncStatus.mockBlocked,
          errorMessage: 'Fake GPS terdeteksi! Koordinat ditolak.',
        );
        return;
      }

      if (secStatus != GpsSecurityStatus.ready) {
        debugPrint('⚠️ [GPS Tracker] GPS belum siap atau izin tidak diberikan.');
        trackingNotifier.value = trackingNotifier.value.copyWith(
          syncStatus: GpsSyncStatus.error,
          errorMessage: 'Layanan GPS tidak aktif atau izin ditolak.',
        );
        return;
      }

      // B. Ambil koordinat GPS akurasi tinggi
      final position = await getCurrentPosition();
      if (position == null) {
        debugPrint('⚠️ [GPS Tracker] Gagal membaca koordinat GPS perangkat.');
        return;
      }

      // C. Validasi koordinat GPS & deteksi impossible jump
      final coordVal = SecurityManager.instance.validateCoordinate(
        position.latitude,
        position.longitude,
        previousPosition: _previousPosition,
        previousTime: _previousPositionTime,
        currentTime: DateTime.now(),
      );
      if (!coordVal.isValid) {
        debugPrint('⚠️ [GPS Security] Koordinat ditolak: ${coordVal.message}');
        if (coordVal.isSuspiciousJump) {
          trackingNotifier.value = trackingNotifier.value.copyWith(
            syncStatus: GpsSyncStatus.mockBlocked,
            errorMessage: coordVal.message,
          );
          return;
        }
      }

      // D. Hitung kecepatan dalam satuan km/jam (m/s * 3.6)
      double speedKmh = 0.0;
      if (position.speed > 0.3) {
        speedKmh = position.speed * 3.6;
      }

      // E. Hitung Heading / Bearing Arah Kendaraan
      double? currentHeading;
      if (_previousPosition != null) {
        final double distMeters = Geolocator.distanceBetween(
          _previousPosition!.latitude,
          _previousPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distMeters >= 3.0) {
          _accumulatedDistanceKm += (distMeters / 1000.0);
          currentHeading = DirectionHelper.calculateBearing(
            startLat: _previousPosition!.latitude,
            startLng: _previousPosition!.longitude,
            endLat: position.latitude,
            endLng: position.longitude,
          );
          _lastKnownHeading = currentHeading;
        } else {
          currentHeading = _lastKnownHeading;
        }
      } else if (position.heading > 0.0 && position.heading <= 360.0) {
        currentHeading = DirectionHelper.normalizeDegree(position.heading);
        _lastKnownHeading = currentHeading;
      }

      final String? headingCardinal = currentHeading != null
          ? DirectionHelper.getCardinalDirection(currentHeading)
          : null;

      _previousPosition = position;
      _previousPositionTime = DateTime.now();
      _updateCounter++;

      final double formattedSpeed = double.parse(speedKmh.toStringAsFixed(1));
      final double formattedDistance = double.parse(_accumulatedDistanceKm.toStringAsFixed(2));

      // F. Update baris data pada tabel `bookings` di Supabase
      final updatePayload = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'kecepatan': formattedSpeed,
        'jarak': formattedDistance,
        'sinyal': 1,
      };

      if (currentHeading != null) {
        updatePayload['heading'] = double.parse(currentHeading.toStringAsFixed(1));
      }

      try {
        await Supabase.instance.client
            .from('bookings')
            .update(updatePayload)
            .eq('id', bookingId);
      } catch (e) {
        // Fallback jika kolom tertentu belum ada di schema
        final fallbackPayload = <String, dynamic>{
          'latitude': position.latitude,
          'longitude': position.longitude,
          'kecepatan': formattedSpeed,
        };
        await Supabase.instance.client
            .from('bookings')
            .update(fallbackPayload)
            .eq('id', bookingId);
      }

      debugPrint(
        '📍 [GPS Tracker 5s #$_updateCounter] Berhasil terkirim ke Supabase -> '
        'Lat: ${position.latitude.toStringAsFixed(6)}, '
        'Lng: ${position.longitude.toStringAsFixed(6)}, '
        'Speed: $formattedSpeed km/j, '
        'Distance: $formattedDistance km, '
        'Heading: ${currentHeading != null ? "${currentHeading.toStringAsFixed(1)}° ($headingCardinal)" : "Standby"}',
      );

      trackingNotifier.value = trackingNotifier.value.copyWith(
        isTracking: true,
        bookingId: bookingId,
        lastPosition: position,
        speedKmh: formattedSpeed,
        totalDistanceKm: formattedDistance,
        heading: currentHeading,
        headingCardinal: headingCardinal,
        lastUpdateTime: DateTime.now(),
        syncStatus: GpsSyncStatus.success,
        errorMessage: null,
        updateCount: _updateCounter,
      );
    } catch (e) {
      debugPrint('❌ [GPS Tracker] Error saat mengirim koordinat ke Supabase: $e');
      trackingNotifier.value = trackingNotifier.value.copyWith(
        syncStatus: GpsSyncStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isSyncing = false;
    }
  }
}
