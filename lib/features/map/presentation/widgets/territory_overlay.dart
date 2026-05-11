import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../territory/presentation/providers/territory_provider.dart';

class TerritoryOverlayWidget extends StatefulWidget {
  final MapboxMap mapboxMap;
  final TerritoryState territoryState;
  final TerritoryNotifier territoryNotifier;
  final String? currentUserId;
  const TerritoryOverlayWidget({
    super.key,
    required this.mapboxMap,
    required this.territoryState,
    required this.territoryNotifier,
    this.currentUserId,
  });
  @override State<TerritoryOverlayWidget> createState() => _TerritoryOverlayWidgetState();
}

class _TerritoryOverlayWidgetState extends State<TerritoryOverlayWidget> {
  bool _layersInitialized = false;
  bool _isRendering = false;
  static const String _sourceId = 'territory_src';
  static const String _fillLayerId = 'territory_fill';
  static const String _lineLayerId = 'territory_line';

  @override
  void initState() {
    super.initState();
    // Initial render will happen via didUpdateWidget or a post-frame callback if needed
  }

  @override
  void didUpdateWidget(covariant TerritoryOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.territoryState.ownedCells != widget.territoryState.ownedCells || !_layersInitialized) {
      _renderTerritories();
    }
  }

  Future<void> _initializeLayers() async {
    try {
      final style = widget.mapboxMap.style;
      
      // Add source if not exists
      if (!await style.styleSourceExists(_sourceId)) {
        await style.addSource(GeoJsonSource(
          id: _sourceId,
          data: jsonEncode({'type': 'FeatureCollection', 'features': []}),
        ));
      }

      // Add fill layer if not exists
      if (!await style.styleLayerExists(_fillLayerId)) {
        final fillLayer = FillLayer(id: _fillLayerId, sourceId: _sourceId);
        fillLayer.fillColor = Colors.blue.toARGB32();
        fillLayer.fillOpacity = 0.35;
        await style.addLayer(fillLayer);
      }

      // Add line layer if not exists
      if (!await style.styleLayerExists(_lineLayerId)) {
        final lineLayer = LineLayer(id: _lineLayerId, sourceId: _sourceId);
        lineLayer.lineColor = Colors.white.toARGB32();
        lineLayer.lineWidth = 2.0;
        lineLayer.lineOpacity = 0.7;
        await style.addLayer(lineLayer);
      }

      _layersInitialized = true;
    } catch (e) {
      debugPrint('Territory layer init error: $e');
    }
  }

  Future<void> _renderTerritories() async {
    if (_isRendering) return;
    _isRendering = true;

    try {
      if (!_layersInitialized) {
        await _initializeLayers();
      }

      final cells = widget.territoryState.ownedCells.values.toList();
      final features = cells.map((cell) {
        final isOwn = cell.ownerId == widget.currentUserId;
        final boundary = widget.territoryNotifier.getCellBoundary(cell.cellId);
        final ring = <List<double>>[];
        for (final (lat, lng) in boundary) {
          ring.add([lng, lat]);
        }
        if (ring.isNotEmpty) {
          ring.add(ring.first);
        }

        return {
          'type': 'Feature',
          'properties': {
            'ownerId': cell.ownerId,
            'isOwn': isOwn,
            'isContested': cell.isContested,
            'ownerColor': cell.ownerColor,
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [ring],
          },
        };
      }).toList();

      final geoJson = jsonEncode({'type': 'FeatureCollection', 'features': features});

      final style = widget.mapboxMap.style;
      final source = await style.getSource(_sourceId);
      if (source is GeoJsonSource) {
        await source.updateGeoJSON(geoJson);
      }
    } catch (e) {
      debugPrint('Territory update error: $e');
    } finally {
      _isRendering = false;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}