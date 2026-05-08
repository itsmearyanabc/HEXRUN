/// H3 geospatial constants for HexRun
class H3Constants {
  H3Constants._();

  /// H3 resolution level — res 9 = ~105m² per cell
  static const int resolution = 9;

  /// Capture ring radius (k-ring = 1) — captures 7 cells
  static const int captureRingRadius = 1;

  /// Influence ring radius (k-ring = 2) — 19 cells
  static const int influenceRingRadius = 2;

  /// Number of cells in a k-ring of radius 1
  static const int captureRingCellCount = 7;

  /// Number of cells in a k-ring of radius 2
  static const int influenceRingCellCount = 19;
}