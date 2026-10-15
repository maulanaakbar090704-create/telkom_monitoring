import 'dart:math' as math;

/// Helper untuk menghitung arah kendaraan (Heading / Bearing)
/// Menggunakan kalkulasi forward azimuth pada trigonometri bola
class DirectionHelper {
  DirectionHelper._();

  /// Menghitung sudut arah (bearing) dari titik A ke titik B dalam satuan derajat (0° - 360°)
  static double calculateBearing({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final double phi1 = _degToRad(startLat);
    final double phi2 = _degToRad(endLat);
    final double deltaLambda = _degToRad(endLng - startLng);

    final double y = math.sin(deltaLambda) * math.cos(phi2);
    final double x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final double theta = math.atan2(y, x);
    final double bearing = (_radToDeg(theta) + 360.0) % 360.0;

    return normalizeDegree(bearing);
  }

  /// Menormalisasi derajat agar selalu berada di rentang 0.0 - 360.0
  static double normalizeDegree(double degree) {
    double normalized = degree % 360.0;
    if (normalized < 0) {
      normalized += 360.0;
    }
    return double.parse(normalized.toStringAsFixed(1));
  }

  /// Mengonversi derajat heading ke 8 nama mata angin bahasa Indonesia
  static String getCardinalDirection(double degree) {
    final double normalized = (degree % 360.0 + 360.0) % 360.0;

    if (normalized >= 337.5 || normalized < 22.5) {
      return 'Utara';
    } else if (normalized >= 22.5 && normalized < 67.5) {
      return 'Timur Laut';
    } else if (normalized >= 67.5 && normalized < 112.5) {
      return 'Timur';
    } else if (normalized >= 112.5 && normalized < 157.5) {
      return 'Tenggara';
    } else if (normalized >= 157.5 && normalized < 202.5) {
      return 'Selatan';
    } else if (normalized >= 202.5 && normalized < 247.5) {
      return 'Barat Daya';
    } else if (normalized >= 247.5 && normalized < 292.5) {
      return 'Barat';
    } else {
      return 'Barat Laut';
    }
  }

  /// Label terformat: "Timur Laut (45°)"
  static String formatHeading(double? degree) {
    if (degree == null) return 'Standby';
    final cardinal = getCardinalDirection(degree);
    return '$cardinal (${degree.toStringAsFixed(0)}°)';
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);
}
