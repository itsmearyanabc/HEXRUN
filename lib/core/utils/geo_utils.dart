import 'dart:math' as math;

/// Geographic utility functions for HexRun
class GeoUtils {
  GeoUtils._();

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  static double haversineDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c * 1000;
  }

  /// Calculate speed in km/h given distance in meters and time in milliseconds
  static double calculateSpeedKmh(double distanceM, int timeMs) {
    if (timeMs <= 0) return 0.0;
    final double timeHours = timeMs / (1000 * 3600);
    final double distanceKm = distanceM / 1000;
    return distanceKm / timeHours;
  }

  /// Check if a GPS reading is within acceptable accuracy
  static bool isAccuracyAcceptable(double accuracyM, {double maxAccuracy = 10.0}) {
    return accuracyM <= maxAccuracy;
  }

  /// Check if speed is within acceptable range (anti-cheat)
  static bool isSpeedAcceptable(double speedKmh, {double maxSpeed = 50.0}) {
    return speedKmh <= maxSpeed;
  }

  /// Check if position jump is within acceptable range
  static bool isJumpAcceptable(double jumpM, {double maxJump = 200.0}) {
    return jumpM <= maxJump;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}