import 'package:h3_flutter/h3_flutter.dart';
import 'package:h3_common/h3_common.dart';
import '../../../../core/constants/h3_constants.dart';

/// H3 geospatial indexing service for hex cell management
class H3Service {
  final H3 _h3 = const H3Factory().load();

  /// Get the H3 cell ID for a given lat/lng at the configured resolution
  String latLngToCell(double lat, double lng) {
    final geo = GeoCoord(lat: lat, lon: lng);
    final bigIntId = _h3.geoToH3(geo, H3Constants.resolution);
    return bigIntId.toRadixString(16);
  }

  /// Get the center lat/lng of an H3 cell
  (double lat, double lng) cellToLatLng(String cellId) {
    final bigIntId = BigInt.parse(cellId, radix: 16);
    final latLng = _h3.h3ToGeo(bigIntId);
    return (latLng.lat, latLng.lon);
  }

  /// Get the boundary polygon of an H3 cell (list of lat/lng vertices)
  List<(double lat, double lng)> cellBoundary(String cellId) {
    final bigIntId = BigInt.parse(cellId, radix: 16);
    final boundary = _h3.h3ToGeoBoundary(bigIntId);
    return boundary.map((p) => (p.lat, p.lon)).toList();
  }

  /// Get the ring of neighboring cells at distance k
  List<String> gridDisk(String cellId, int k) {
    final bigIntId = BigInt.parse(cellId, radix: 16);
    final ring = _h3.kRing(bigIntId, k);
    return ring.map((e) => e.toRadixString(16)).toList();
  }

  /// Check if a cell is a valid H3 cell
  bool isValidCell(String cellId) {
    final bigIntId = BigInt.tryParse(cellId, radix: 16);
    if (bigIntId == null) return false;
    return _h3.h3IsValid(bigIntId);
  }

  /// Get the resolution of a cell
  int getResolution(String cellId) {
    final bigIntId = BigInt.parse(cellId, radix: 16);
    return _h3.h3GetResolution(bigIntId);
  }

  /// Get the area of a cell in km2
  double cellAreaKm2(String cellId) {
    final bigIntId = BigInt.parse(cellId, radix: 16);
    return _h3.cellArea(bigIntId, H3Units.km); // It seems H3Units are m, km, rad and cellArea takes H3Units
  }

  /// Check if two cells are neighbors
  bool areNeighbors(String a, String b) {
    final bigIntA = BigInt.parse(a, radix: 16);
    final bigIntB = BigInt.parse(b, radix: 16);
    return _h3.h3IndexesAreNeighbors(bigIntA, bigIntB);
  }

  /// Get the distance between two cells in grid steps
  int gridDistance(String a, String b) {
    try {
      final bigIntA = BigInt.parse(a, radix: 16);
      final bigIntB = BigInt.parse(b, radix: 16);
      return _h3.h3Distance(bigIntA, bigIntB);
    } catch (_) {
      return -1;
    }
  }
}