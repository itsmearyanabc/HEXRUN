/// Game mechanics constants for HexRun
class GameConstants {
  GameConstants._();

  // --- Capture Algorithm ---
  /// Ticks required to capture an unowned cell
  static const int freshCellTicks = 1;

  /// Base ticks required to capture an enemy cell
  static const int enemyCellTicks = 5;

  /// Maximum defense level for a hex cell
  static const int maxDefenseLevel = 5;

  /// Speed threshold (km/h) for capture bonus
  static const double speedBonusKmh = 12.0;

  // --- GPS ---
  /// GPS interval during active run (milliseconds)
  static const int gpsIntervalMs = 3000;

  /// GPS interval when idle (milliseconds)
  static const int gpsIntervalIdleMs = 15000;

  /// Minimum displacement to register (meters)
  static const double minDisplacementM = 5.0;

  /// Maximum GPS accuracy to accept (meters)
  static const double gpsAccuracy = 10.0;

  // --- Anti-Cheat ---
  /// Maximum speed before flagging as cheat (km/h)
  static const double maxSpeedKmh = 50.0;

  /// Maximum position jump in meters per 3s tick
  static const double maxJumpM = 200.0;

  /// Minimum time between writes (milliseconds)
  static const int minWriteIntervalMs = 1000;

  // --- Territory ---
  /// Hours before defense decay applies
  static const int defenseDecayHoursPerLevel = 24;

  /// Days before unclaimed cell reverts
  static const int territoryDecayDays = 7;

  /// Radius for capture detection (k-ring distance)
  static const int captureRadiusK = 1;

  /// XP earned for capturing an unowned cell
  static const int xpPerCapture = 10;

  /// XP earned for contesting an enemy cell
  static const int xpPerContest = 5;

  /// Bonus XP for every 10 cells captured in a cluster
  static const int clusterBonusXp = 50;

  // --- Leaderboard ---
  /// Leaderboard rank update interval (minutes)
  static const int leaderboardUpdateIntervalMin = 5;

  /// Max visible players on map
  static const int maxVisiblePlayers = 100;
}