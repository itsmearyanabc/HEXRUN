import 'package:flutter/material.dart';

/// HexRun app theme configuration
class AppTheme {
  AppTheme._();

  // --- Brand Colors ---
  static const Color _primaryColor = Color(0xFF1A73E8);
  static const Color _secondaryColor = Color(0xFF34A853);
  static const Color _accentColor = Color(0xFFFF6D01);

  /// Public brand accent (orange) for nav, CTAs, map highlights
  static const Color accent = _accentColor;
  static const Color _dangerColor = Color(0xFFEA4335);
  static const Color _darkBg = Color(0xFF0D1B2A);
  static const Color _darkSurface = Color(0xFF1B2838);
  static const Color _darkCard = Color(0xFF243447);

  /// Light theme
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
        ).copyWith(secondary: _secondaryColor, error: _dangerColor),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
        ),
      );

  /// Dark theme (default for map view)
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
        ).copyWith(secondary: _secondaryColor, error: _dangerColor),
        scaffoldBackgroundColor: _darkBg,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: _darkSurface,
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          color: _darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkSurface,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  // --- Territory Colors ---
  static const Color unclaimedHex = Color(0x40808080);
  static const int capturedHexAlpha = 0x80;
  static const int influenceHexAlpha = 0x30;

  // --- Map Styles ---
  static const String mapStyleDark = 'mapbox://styles/mapbox/dark-v11';
  static const String mapStyleStreets = 'mapbox://styles/mapbox/streets-v12';
  static const String mapStyleOutdoors = 'mapbox://styles/mapbox/outdoors-v12';
}