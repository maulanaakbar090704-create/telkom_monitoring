import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Status validasi koordinat GPS
class CoordinateValidationResult {
  final bool isValid;
  final String? message;
  final bool isSuspiciousJump;

  const CoordinateValidationResult({
    required this.isValid,
    this.message,
    this.isSuspiciousJump = false,
  });

  factory CoordinateValidationResult.valid() =>
      const CoordinateValidationResult(isValid: true);

  factory CoordinateValidationResult.invalid(String message, {bool isSuspicious = false}) =>
      CoordinateValidationResult(
        isValid: false,
        message: message,
        isSuspiciousJump: isSuspicious,
      );
}

/// Pengelola keamanan terpusat:
/// 1. Rate Limiting Brute Force Login Peminjam
/// 2. Validasi Koordinat GPS & Deteksi Spoofing (Impossible Jumps)
/// 3. Sanitasi Input & Penyamaran Pesan Error
class SecurityManager {
  SecurityManager._();
  static final SecurityManager instance = SecurityManager._();

  // =========================================================================
  // 1. RATE LIMITING & BRUTE FORCE DEFENSE (LOGIN PEMINJAM)
  // =========================================================================
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationSeconds = 60;

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  Timer? _lockoutTimer;

  final ValueNotifier<int> remainingLockoutNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> remainingAttemptsNotifier = ValueNotifier<int>(maxLoginAttempts);

  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    final now = DateTime.now();
    if (now.isBefore(_lockoutUntil!)) {
      return true;
    } else {
      _resetLockout();
      return false;
    }
  }

  int get remainingLockoutSeconds {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Catat kegagalan login dan picu lockout jika melampaui batas
  void recordFailedAttempt() {
    _failedAttempts++;
    final remaining = maxLoginAttempts - _failedAttempts;
    remainingAttemptsNotifier.value = remaining > 0 ? remaining : 0;

    if (_failedAttempts >= maxLoginAttempts) {
      _lockoutUntil = DateTime.now().add(const Duration(seconds: lockoutDurationSeconds));
      remainingLockoutNotifier.value = lockoutDurationSeconds;

      _lockoutTimer?.cancel();
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final remaining = remainingLockoutSeconds;
        remainingLockoutNotifier.value = remaining;
        if (remaining <= 0) {
          _resetLockout();
        }
      });
    }
  }

  /// Reset counter saat login berhasil
  void recordSuccessfulLogin() {
    _resetLockout();
  }

  void _resetLockout() {
    _failedAttempts = 0;
    _lockoutUntil = null;
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    remainingLockoutNotifier.value = 0;
    remainingAttemptsNotifier.value = maxLoginAttempts;
  }

  // =========================================================================
  // 2. VALIDASI KOORDINAT & DETEKSI SPOOFING GPS (IMPOSSIBLE JUMPS)
  // =========================================================================
  static const double minLatIndonesia = -11.5;
  static const double maxLatIndonesia = 6.5;
  static const double minLngIndonesia = 94.5;
  static const double maxLngIndonesia = 141.5;

  static const double maxRealisticSpeedKmh = 160.0;
  static const double maxJumpMetersInShortInterval = 1200.0;

  CoordinateValidationResult validateCoordinate(
    double? lat,
    double? lng, {
    Position? previousPosition,
    DateTime? previousTime,
    DateTime? currentTime,
  }) {
    if (lat == null || lng == null) {
      return CoordinateValidationResult.invalid('Koordinat GPS tidak tersedia.');
    }

    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
      return CoordinateValidationResult.invalid('Koordinat cacat (NaN/Infinite).');
    }

    // Deteksi "Null Island" (0.0, 0.0)
    if (lat.abs() < 0.0001 && lng.abs() < 0.0001) {
      return CoordinateValidationResult.invalid('Koordinat tidak valid (Null Island).');
    }

    // Batas wilayah kedaulatan Indonesia
    if (lat < minLatIndonesia ||
        lat > maxLatIndonesia ||
        lng < minLngIndonesia ||
        lng > maxLngIndonesia) {
      return CoordinateValidationResult.invalid(
        'Koordinat berada di luar wilayah Indonesia ($lat, $lng).',
      );
    }

    // Deteksi lompatan teleportasi tak wajar (impossible jump)
    if (previousPosition != null) {
      final double distanceMeters = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        lat,
        lng,
      );

      final now = currentTime ?? DateTime.now();
      final prev = previousTime ?? now.subtract(const Duration(seconds: 5));
      final double timeDiffSec = now.difference(prev).inMilliseconds / 1000.0;

      if (timeDiffSec > 0 && timeDiffSec <= 6.0 && distanceMeters > maxJumpMetersInShortInterval) {
        return CoordinateValidationResult.invalid(
          'Lompatan lokasi drastis (${(distanceMeters / 1000).toStringAsFixed(1)} km dlm ${timeDiffSec.toStringAsFixed(0)}s). Kemungkinan Fake GPS.',
          isSuspicious: true,
        );
      }

      if (timeDiffSec > 0) {
        final double calculatedSpeedKmh = (distanceMeters / timeDiffSec) * 3.6;
        if (calculatedSpeedKmh > maxRealisticSpeedKmh) {
          return CoordinateValidationResult.invalid(
            'Kecepatan perpindahan tidak wajar: ${calculatedSpeedKmh.toStringAsFixed(0)} km/h. Periksa akurasi sinyal peminjam.',
            isSuspicious: true,
          );
        }
      }
    }

    return CoordinateValidationResult.valid();
  }

  // =========================================================================
  // 3. SANITASI INPUT & DATA MASKING
  // =========================================================================
  String sanitizeInput(String input) {
    return input.replaceAll(RegExp(r'''[<>"';\\]'''), '').trim();
  }

  String sanitizeErrorMessage(dynamic error) {
    final str = error.toString().toLowerCase();
    if (str.contains('invalid login credentials') || str.contains('invalid grant')) {
      return 'ID Karyawan atau Kata Sandi salah.';
    }
    if (str.contains('network') || str.contains('socket') || str.contains('connection')) {
      return 'Gagal terhubung ke server. Periksa jaringan internet Anda.';
    }
    if (str.contains('timeout')) {
      return 'Permintaan waktu habis. Silakan coba lagi.';
    }
    return 'Terjadi kesalahan sistem. Silakan hubungi Super Admin IT.';
  }

  void dispose() {
    _lockoutTimer?.cancel();
  }
}
