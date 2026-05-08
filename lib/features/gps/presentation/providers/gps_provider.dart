import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/location_service.dart';
import '../../../../core/utils/geo_utils.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

class GpsState {
  final bool isTracking;
  final ValidatedPosition? currentPosition;
  final double totalDistanceM;
  final double currentSpeedKmh;
  final Duration elapsed;
  final String? error;
  const GpsState({this.isTracking = false, this.currentPosition, this.totalDistanceM = 0, this.currentSpeedKmh = 0, this.elapsed = Duration.zero, this.error});
  GpsState copyWith({bool? isTracking, ValidatedPosition? currentPosition, double? totalDistanceM, double? currentSpeedKmh, Duration? elapsed, String? error}) =>
      GpsState(isTracking: isTracking ?? this.isTracking, currentPosition: currentPosition ?? this.currentPosition,
        totalDistanceM: totalDistanceM ?? this.totalDistanceM, currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
        elapsed: elapsed ?? this.elapsed, error: error);
}

class GpsStateNotifier extends StateNotifier<GpsState> {
  final LocationService _locationService;
  StreamSubscription<ValidatedPosition>? _trackingSub;
  DateTime? _startTime;
  GpsStateNotifier(this._locationService) : super(const GpsState());

  void startTracking() {
    _startTime = DateTime.now();
    state = state.copyWith(isTracking: true, error: null);
    _trackingSub = _locationService.startTracking().listen((pos) {
      if (pos.isValid) {
        final speedKmh = pos.speed * 3.6;
        double newDist = state.totalDistanceM;
        if (state.currentPosition != null) {
          newDist += GeoUtils.haversineDistance(
            state.currentPosition!.latitude, state.currentPosition!.longitude, pos.latitude, pos.longitude);
        }
        state = state.copyWith(currentPosition: pos, totalDistanceM: newDist, currentSpeedKmh: speedKmh,
          elapsed: DateTime.now().difference(_startTime!));
      }
    });
  }

  void stopTracking() { _trackingSub?.cancel(); _trackingSub = null; state = state.copyWith(isTracking: false); }
  Future<bool> requestPermissions() => _locationService.requestPermissions();
  Future<ValidatedPosition?> getCurrentPosition() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos.isValid) { state = state.copyWith(currentPosition: pos); return pos; }
    state = state.copyWith(error: pos.rejectionReason); return null;
  }
  @override void dispose() { _trackingSub?.cancel(); super.dispose(); }
}

final gpsStateProvider = StateNotifierProvider<GpsStateNotifier, GpsState>((ref) {
  return GpsStateNotifier(ref.watch(locationServiceProvider));
});
final isTrackingProvider = Provider<bool>((ref) => ref.watch(gpsStateProvider).isTracking);
final currentPositionProvider = Provider<ValidatedPosition?>((ref) => ref.watch(gpsStateProvider).currentPosition);