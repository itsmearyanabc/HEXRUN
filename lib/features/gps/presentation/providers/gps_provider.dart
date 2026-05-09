import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/location_service.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../territory/presentation/providers/territory_provider.dart';

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
  final List<(double, double)> routePoints;
  /// Set after an automatic loop capture; UI shows snackbar then clears via [acknowledgeLoopFeedback].
  final int? lastLoopHexCount;
  const GpsState({
    this.isTracking = false,
    this.currentPosition,
    this.totalDistanceM = 0,
    this.currentSpeedKmh = 0,
    this.elapsed = Duration.zero,
    this.error,
    this.routePoints = const [],
    this.lastLoopHexCount,
  });
  GpsState copyWith({
    bool? isTracking,
    ValidatedPosition? currentPosition,
    double? totalDistanceM,
    double? currentSpeedKmh,
    Duration? elapsed,
    String? error,
    List<(double, double)>? routePoints,
    int? lastLoopHexCount,
    bool clearLoopFeedback = false,
  }) =>
      GpsState(
        isTracking: isTracking ?? this.isTracking,
        currentPosition: currentPosition ?? this.currentPosition,
        totalDistanceM: totalDistanceM ?? this.totalDistanceM,
        currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
        elapsed: elapsed ?? this.elapsed,
        error: error ?? this.error,
        routePoints: routePoints ?? this.routePoints,
        lastLoopHexCount: clearLoopFeedback ? null : (lastLoopHexCount ?? this.lastLoopHexCount),
      );
}

class GpsStateNotifier extends StateNotifier<GpsState> {
  final LocationService _locationService;
  final Ref _ref;
  StreamSubscription<ValidatedPosition>? _trackingSub;
  DateTime? _startTime;
  final List<(double, double)> _routeBuffer = [];
  DateTime? _lastLoopCaptureAt;

  GpsStateNotifier(this._locationService, this._ref) : super(const GpsState());

  void acknowledgeLoopFeedback() {
    state = state.copyWith(clearLoopFeedback: true);
  }

  Future<void> startTracking() async {
    final ok = await _locationService.requestPermissions();
    if (!ok) {
      state = state.copyWith(
        isTracking: false,
        error: 'Turn on location services and allow HexRun to use your location.',
      );
      return;
    }
    _startTime = DateTime.now();
    _routeBuffer.clear();
    _lastLoopCaptureAt = null;
    state = state.copyWith(isTracking: true, error: null, routePoints: const [], clearLoopFeedback: true);
    _trackingSub?.cancel();
    _trackingSub = _locationService.startTracking().listen((pos) {
      if (pos.isValid) {
        final speedKmh = pos.speed * 3.6;
        double newDist = state.totalDistanceM;
        if (state.currentPosition != null) {
          newDist += GeoUtils.haversineDistance(
            state.currentPosition!.latitude,
            state.currentPosition!.longitude,
            pos.latitude,
            pos.longitude,
          );
        }
        state = state.copyWith(
          currentPosition: pos,
          totalDistanceM: newDist,
          currentSpeedKmh: speedKmh,
          elapsed: DateTime.now().difference(_startTime!),
        );
        if (state.isTracking) {
          _appendRouteAndMaybeCaptureLoop(pos);
        }
      }
    });
  }

  void _appendRouteAndMaybeCaptureLoop(ValidatedPosition pos) {
    final p = (pos.latitude, pos.longitude);
    if (_routeBuffer.isEmpty) {
      _routeBuffer.add(p);
      _syncRouteToState();
      return;
    }
    final last = _routeBuffer.last;
    final step = GeoUtils.haversineDistance(last.$1, last.$2, p.$1, p.$2);
    if (step < GameConstants.routeMinSegmentM) return;
    _routeBuffer.add(p);
    if (_routeBuffer.length > GameConstants.maxRoutePoints) {
      _routeBuffer.removeRange(0, _routeBuffer.length - GameConstants.maxRoutePoints);
    }
    _syncRouteToState();
    unawaited(_tryClosedLoopCapture());
  }

  void _syncRouteToState() {
    state = state.copyWith(routePoints: List<(double, double)>.unmodifiable(_routeBuffer));
  }

  Future<void> _tryClosedLoopCapture() async {
    if (_routeBuffer.length < GameConstants.minLoopVertices) return;
    final now = DateTime.now();
    if (_lastLoopCaptureAt != null &&
        now.difference(_lastLoopCaptureAt!).inMilliseconds < GameConstants.loopCaptureCooldownMs) {
      return;
    }
    final first = _routeBuffer.first;
    final last = _routeBuffer.last;
    final gap = GeoUtils.haversineDistance(first.$1, first.$2, last.$1, last.$2);
    if (gap > GameConstants.loopClosingRadiusM) return;
    double perimeter = gap;
    for (int i = 0; i < _routeBuffer.length - 1; i++) {
      final a = _routeBuffer[i], b = _routeBuffer[i + 1];
      perimeter += GeoUtils.haversineDistance(a.$1, a.$2, b.$1, b.$2);
    }
    if (perimeter < GameConstants.minLoopPerimeterM) return;
    final ring = List<(double, double)>.from(_routeBuffer);
    _lastLoopCaptureAt = now;
    _routeBuffer
      ..clear()
      ..add(last);
    _syncRouteToState();
    try {
      final result = await _ref.read(territoryProvider.notifier).captureClosedLoop(ring);
      final n = result?.totalCaptured ?? 0;
      state = state.copyWith(lastLoopHexCount: n);
    } catch (e) {
      state = state.copyWith(error: 'Could not save territory: $e');
    }
  }

  void stopTracking() {
    _trackingSub?.cancel();
    _trackingSub = null;
    _locationService.stopTracking();
    _routeBuffer.clear();
    state = state.copyWith(isTracking: false, routePoints: const []);
  }

  Future<bool> requestPermissions() => _locationService.requestPermissions();

  Future<ValidatedPosition?> getCurrentPosition() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos.isValid) {
      state = state.copyWith(currentPosition: pos);
      return pos;
    }
    state = state.copyWith(error: pos.rejectionReason);
    return null;
  }

  @override
  void dispose() {
    _trackingSub?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }
}

final gpsStateProvider = StateNotifierProvider<GpsStateNotifier, GpsState>((ref) {
  return GpsStateNotifier(ref.watch(locationServiceProvider), ref);
});
final isTrackingProvider = Provider<bool>((ref) => ref.watch(gpsStateProvider).isTracking);
final currentPositionProvider = Provider<ValidatedPosition?>((ref) => ref.watch(gpsStateProvider).currentPosition);
