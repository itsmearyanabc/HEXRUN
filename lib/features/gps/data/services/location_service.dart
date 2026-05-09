import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/utils/geo_utils.dart';

/// GPS position data with validation metadata
class ValidatedPosition {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double altitude;
  final DateTime timestamp;
  final bool isValid;
  final String? rejectionReason;

  const ValidatedPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.altitude,
    required this.timestamp,
    required this.isValid,
    this.rejectionReason,
  });
}

/// Location service handling GPS tracking with anti-cheat validation
class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  StreamController<ValidatedPosition>? _trackingController;
  Position? _lastPosition;

  /// Live updates for runs. Does not request permission — call [requestPermissions] first.
  Stream<ValidatedPosition> startTracking() {
    stopTracking();
    final controller = StreamController<ValidatedPosition>.broadcast();
    _trackingController = controller;
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: GameConstants.minDisplacementM.round(),
        // Do not set timeLimit here: it causes periodic timeouts and a dead-looking map.
      ),
    ).listen(
      (position) {
        final validated = _validatePosition(position);
        if (validated.isValid) _lastPosition = position;
        if (!controller.isClosed) controller.add(validated);
      },
      onError: (error) {
        debugPrint('GPS Error: $error');
        if (!controller.isClosed) controller.addError(error);
      },
    );
    return controller.stream;
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _trackingController?.close();
    _trackingController = null;
  }

  Future<ValidatedPosition> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return ValidatedPosition(
        latitude: 0, longitude: 0, accuracy: 0, speed: 0,
        altitude: 0, timestamp: DateTime.now(), isValid: false,
        rejectionReason: 'Location service disabled',
      );
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return ValidatedPosition(
          latitude: 0, longitude: 0, accuracy: 0, speed: 0,
          altitude: 0, timestamp: DateTime.now(), isValid: false,
          rejectionReason: 'Location permission denied',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return ValidatedPosition(
        latitude: 0, longitude: 0, accuracy: 0, speed: 0,
        altitude: 0, timestamp: DateTime.now(), isValid: false,
        rejectionReason: 'Location permission permanently denied',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return _validatePosition(position);
  }

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  ValidatedPosition _validatePosition(Position position) {
    if (!GeoUtils.isAccuracyAcceptable(
      position.accuracy,
      maxAccuracy: GameConstants.gpsAccuracyLoose,
    )) {
      return ValidatedPosition(
        latitude: position.latitude, longitude: position.longitude,
        accuracy: position.accuracy, speed: position.speed,
        altitude: position.altitude, timestamp: position.timestamp,
        isValid: false, rejectionReason: 'GPS accuracy too low: ${position.accuracy}m',
      );
    }
    final speedKmh = position.speed * 3.6;
    if (!GeoUtils.isSpeedAcceptable(speedKmh)) {
      return ValidatedPosition(
        latitude: position.latitude, longitude: position.longitude,
        accuracy: position.accuracy, speed: position.speed,
        altitude: position.altitude, timestamp: position.timestamp,
        isValid: false, rejectionReason: 'Speed too high: ${speedKmh.toStringAsFixed(1)} km/h',
      );
    }
    if (_lastPosition != null) {
      final jump = GeoUtils.haversineDistance(
        _lastPosition!.latitude, _lastPosition!.longitude,
        position.latitude, position.longitude,
      );
      if (!GeoUtils.isJumpAcceptable(jump)) {
        return ValidatedPosition(
          latitude: position.latitude, longitude: position.longitude,
          accuracy: position.accuracy, speed: position.speed,
          altitude: position.altitude, timestamp: position.timestamp,
          isValid: false, rejectionReason: 'Position jump too large: ${jump.toStringAsFixed(0)}m',
        );
      }
    }
    return ValidatedPosition(
      latitude: position.latitude, longitude: position.longitude,
      accuracy: position.accuracy, speed: position.speed,
      altitude: position.altitude, timestamp: position.timestamp,
      isValid: true,
    );
  }

  void dispose() => stopTracking();
}