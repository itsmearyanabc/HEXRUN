/// App configuration constants
class AppConfig {
  AppConfig._();

  // Mapbox
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: 'pk.eyJ1IjoiaXRzbWVhcnlhbmFiYyIsImEiOiJjbW94MjQ2dDkwZDU1MnRzNHc5NG5remJhIn0.f-BJHjIu8mpGo0hgoenzDw',
  );

  // Firebase
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'hexrun-mvp',
  );

  // App Info
  static const String appName = 'HexRun';
  static const String appVersion = '1.0.0';

  // Player defaults
  static const List<String> playerColors = [
    '#1A73E8', // Blue
    '#EA4335', // Red
    '#34A853', // Green
    '#FBBC04', // Yellow
    '#FF6D01', // Orange
    '#46BDC6', // Teal
    '#7B1FA2', // Purple
    '#E91E63', // Pink
  ];
}