import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../territory/presentation/providers/territory_provider.dart';
import '../../../../core/utils/color_utils.dart';

class TerritoryOverlayWidget extends StatefulWidget {
  final MapboxMap mapboxMap;
  final TerritoryState territoryState;
  final String? currentUserId;
  const TerritoryOverlayWidget({super.key, required this.mapboxMap, required this.territoryState, this.currentUserId});
  @override State<TerritoryOverlayWidget> createState() => _TerritoryOverlayWidgetState();
}

class _TerritoryOverlayWidgetState extends State<TerritoryOverlayWidget> {
  @override
  void didUpdateWidget(covariant TerritoryOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.territoryState.ownedCells != widget.territoryState.ownedCells) _renderTerritories();
  }

  Future<void> _renderTerritories() async {
    final cells = widget.territoryState.ownedCells.values.toList();
    if (cells.isEmpty) return;
    try {
      final features = cells.map((cell) {
        final isOwn = cell.ownerId == widget.currentUserId;
        return {'type': 'Feature', 'properties': {'ownerId': cell.ownerId, 'isOwn': isOwn, 'isContested': cell.isContested},
          'geometry': {'type': 'Polygon', 'coordinates': []}};
      }).toList();
      await widget.mapboxMap.style.addSource(GeoJsonSource(id: 'territory_src',
        data: jsonEncode({'type': 'FeatureCollection', 'features': features})));
      
      final fillLayer = FillLayer(id: 'territory_fill', sourceId: 'territory_src');
      fillLayer.fillColor = Colors.blue.value;
      fillLayer.fillOpacity = 0.4;
      await widget.mapboxMap.style.addLayer(fillLayer);

      final lineLayer = LineLayer(id: 'territory_line', sourceId: 'territory_src');
      lineLayer.lineColor = Colors.white.value;
      lineLayer.lineWidth = 1.5;
      lineLayer.lineOpacity = 0.6;
      await widget.mapboxMap.style.addLayer(lineLayer);
    } catch (e) { debugPrint('Territory overlay error: $e'); }
  }

  @override Widget build(BuildContext context) => const SizedBox.shrink();
}