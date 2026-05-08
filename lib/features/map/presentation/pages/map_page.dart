import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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

  @override
  Widget build(BuildContext context) {
    final gpsState = ref.watch(gpsStateProvider);
    final territoryState = ref.watch(territoryProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapbox_map'),
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(
                gpsState.currentPosition?.longitude ?? 0,
                gpsState.currentPosition?.latitude ?? 0)),
              zoom: 15.0,
            ),
          ),
          if (_mapboxMap != null)
            TerritoryOverlayWidget(mapboxMap: _mapboxMap!, territoryState: territoryState, currentUserId: user?.uid),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16,
            child: _StatsCard(gpsState: gpsState, territoryState: territoryState),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 80, left: 0, right: 0,
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
    mapboxMap.location.updateSettings(LocationComponentSettings(enabled: true));
    final pos = ref.read(gpsStateProvider).currentPosition;
    if (pos != null) {
      mapboxMap.flyTo(CameraOptions(center: Point(coordinates: Position(pos.longitude, pos.latitude)), zoom: 15.0),
        MapAnimationOptions(duration: 1000));
    }
  }
}

class _StatsCard extends StatelessWidget {
  final GpsState gpsState;
  final TerritoryState territoryState;
  const _StatsCard({required this.gpsState, required this.territoryState});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _stat(BuildContext ctx, String label, String value, IconData icon) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(icon, size: 20, color: Theme.of(ctx).colorScheme.primary),
      const SizedBox(height: 2), Text(value, style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      Text(label, style: Theme.of(ctx).textTheme.bodySmall)],
  );
}