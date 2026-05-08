import 'package:flutter/material.dart';

/// Color utility functions for HexRun
class ColorUtils {
  ColorUtils._();

  /// Convert hex color string (#RRGGBB) to Flutter Color
  static Color hexToColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Convert Flutter Color to hex string (#RRGGBB)
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Apply alpha to a hex color string, returns a Color
  static Color hexWithAlpha(String hexColor, int alpha) {
    final color = hexToColor(hexColor);
    return color.withAlpha(alpha);
  }

  /// Lighten a color by a percentage (0.0 to 1.0)
  static Color lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Darken a color by a percentage (0.0 to 1.0)
  static Color darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}