import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../gps/data/services/location_service.dart';
import '../widgets/territory_overlay.dart';
import '../widgets/run_controls.dart';
import '../providers/map_provider.dart';
import '../../../gps/presentation/providers/gps_provider.dart';
import '../../../territory/presentation/providers/territory_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});
  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  MapboxMap? _mapboxMap;
  DateTime? _lastCameraFollow;
  bool _routeLayerReady = false;
  bool _didPrefetchTerritory = false;

  static const int _followThrottleMs = 900;

  static final String _emptyRouteGeoJson = jsonEncode({
    'type': 'FeatureCollection',
    'features': <Object>[],
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeLocation());
  }

  Future<void> _primeLocation() async {
    final notifier = ref.read(gpsStateProvider.notifier);
    final ok = await notifier.requestPermissions();
    if (!ok || !mounted) return;
    await notifier.getCurrentPosition();
  }

  void _maybeFollowCamera(ValidatedPosition pos, {required bool tracking}) {
    final map = _mapboxMap;
    if (map == null || !mounted) return;
    final now = DateTime.now();
    final throttle = Duration(milliseconds: tracking ? _followThrottleMs : _followThrottleMs * 2);
    if (_lastCameraFollow != null && now.difference(_lastCameraFollow!) < throttle) return;
    _lastCameraFollow = now;
    map.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(pos.longitude, pos.latitude)),
        zoom: 15.5,
      ),
      MapAnimationOptions(duration: tracking ? 600 : 900),
    );
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData event) async {
    if (_routeLayerReady) return;
    final map = _mapboxMap;
    if (map == null) return;
    try {
      await map.style.addSource(GeoJsonSource(id: 'user_route_src', data: _emptyRouteGeoJson));
      final layer = LineLayer(id: 'user_route_line', sourceId: 'user_route_src');
      layer.lineColor = 0xFFFF6D01;
      layer.lineWidth = 5.5;
      layer.lineOpacity = 0.92;
      layer.lineCap = LineCap.ROUND;
      layer.lineJoin = LineJoin.ROUND;
      await map.style.addLayer(layer);
      _routeLayerReady = true;
      if (mounted) {
        await _pushRouteGeoJson(map, ref.read(gpsStateProvider).routePoints);
      }
    } catch (e) {
      debugPrint('Route layer init: $e');
    }
  }

  Future<void> _pushRouteGeoJson(MapboxMap map, List<(double, double)> pts) async {
    if (!_routeLayerReady) return;
    try {
      final src = await map.style.getSource('user_route_src');
      if (src is! GeoJsonSource) return;
      if (pts.length < 2) {
        await src.updateGeoJSON(_emptyRouteGeoJson);
        return;
      }
      final coords = pts.map((e) => [e.$2, e.$1]).toList();
      final geoJson = jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': <String, Object>{},
            'geometry': {
              'type': 'LineString',
              'coordinates': coords,
            },
          },
        ],
      });
      await src.updateGeoJSON(geoJson);
    } catch (e) {
      debugPrint('Route update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gpsState = ref.watch(gpsStateProvider);
    final territoryState = ref.watch(territoryProvider);
    final user = ref.watch(currentUserProvider);

    ref.listen<GpsState>(gpsStateProvider, (previous, next) {
      final pos = next.currentPosition;
      if (pos != null && pos.isValid) {
        _maybeFollowCamera(pos, tracking: next.isTracking);
        if (!_didPrefetchTerritory) {
          _didPrefetchTerritory = true;
          ref.read(territoryProvider.notifier).loadTerritories(pos.latitude, pos.longitude, 10);
        }
      }
      final err = next.error;
      if (err != null && err.isNotEmpty && err != previous?.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
        );
      }
      final loopN = next.lastLoopHexCount;
      if (loopN != null && loopN != previous?.lastLoopHexCount && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loopN == 0
                  ? 'Loop closed — no new hexes inside (try a larger loop).'
                  : 'Territory claimed: $loopN hexes inside your loop.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(gpsStateProvider.notifier).acknowledgeLoopFeedback();
      }
      final map = _mapboxMap;
      if (map != null && next.routePoints != previous?.routePoints) {
        _pushRouteGeoJson(map, next.routePoints);
      }
    });

    final pos = gpsState.currentPosition;
    final hasFix = pos != null && pos.isValid;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapbox_map'),
            styleUri: AppTheme.mapStyleDark,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            cameraOptions: hasFix
                ? CameraOptions(
                    center: Point(coordinates: Position(pos.longitude, pos.latitude)),
                    zoom: 15.0,
                  )
                : CameraOptions(zoom: 3.0),
          ),
          if (_mapboxMap != null)
            TerritoryOverlayWidget(
              mapboxMap: _mapboxMap!,
              territoryState: territoryState,
              territoryNotifier: ref.read(territoryProvider.notifier),
              currentUserId: user?.uid,
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MapTopBar(
              paddingTop: MediaQuery.of(context).padding.top,
              isTracking: gpsState.isTracking,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 16,
            right: 16,
            child: _StatsCard(gpsState: gpsState, territoryState: territoryState),
          ),
          if (!hasFix)
            Positioned(
              left: 16,
              right: 16,
              bottom: 240,
              child: _LocationHint(onOpenSettings: _primeLocation),
            ),
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: () async {
                await ref.read(gpsStateProvider.notifier).getCurrentPosition();
                if (!context.mounted) return;
                final p = ref.read(gpsStateProvider).currentPosition;
                if (p != null && _mapboxMap != null) {
                  _lastCameraFollow = null;
                  _maybeFollowCamera(p, tracking: true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Still waiting for GPS — try outdoors or tap to retry.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              backgroundColor: AppTheme.accent,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RunControls(
              isTracking: gpsState.isTracking,
              onStart: () => ref.read(gpsStateProvider.notifier).startTracking(),
              onStop: () => ref.read(gpsStateProvider.notifier).stopTracking(),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    ref.read(mapReadyProvider.notifier).state = true;
    _applyLocationPuck(mapboxMap);
    final p = ref.read(gpsStateProvider).currentPosition;
    if (p != null && p.isValid) {
      mapboxMap.flyTo(
        CameraOptions(center: Point(coordinates: Position(p.longitude, p.latitude)), zoom: 15.0),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  Future<void> _applyLocationPuck(MapboxMap mapboxMap) async {
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: 0xFFFF6D01,
        showAccuracyRing: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );
  }
}

class _MapTopBar extends StatelessWidget {
  final double paddingTop;
  final bool isTracking;

  const _MapTopBar({required this.paddingTop, required this.isTracking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, paddingTop + 6, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xE6161616),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 22),
                const SizedBox(width: 8),
                Text(
                  AppConfig.appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (isTracking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationHint extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _LocationHint({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xE61B2838),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.gps_not_fixed, color: AppTheme.accent.withValues(alpha: 0.9)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Getting your location… Allow GPS (precise), disable mock locations, and test outdoors.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
              ),
            ),
            TextButton(
              onPressed: onOpenSettings,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final GpsState gpsState;
  final TerritoryState territoryState;
  const _StatsCard({required this.gpsState, required this.territoryState});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xE60A0A0A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(context, 'Distance', '${(gpsState.totalDistanceM / 1000).toStringAsFixed(2)} km', Icons.straighten),
            _stat(context, 'Speed', '${gpsState.currentSpeedKmh.toStringAsFixed(1)} km/h', Icons.speed),
            _stat(context, 'Hexes', '${territoryState.totalCaptured}', Icons.hexagon),
            _stat(context, 'XP', '${territoryState.xpEarned}', Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext ctx, String label, String value, IconData icon) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppTheme.accent),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
            ),
            Text(
              label,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      );
}
