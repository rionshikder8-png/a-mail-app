import 'package:flutter/material.dart';

/// A-Mail palette derived from the brand mark (blue → violet → orange).
class AColors {
  AColors._();

  static const brandBlue = Color(0xFF1F6BFF);
  static const brandViolet = Color(0xFF7C3AED);
  static const brandOrange = Color(0xFFFF7A1A);
  static const brandRed = Color(0xFFE5483B);
  static const ink = Color(0xFF0F1B3D); // wordmark navy

  // Light
  static const lightBg = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F7FB);
  static const lightSurfaceHigh = Color(0xFFEBEFF7);
  static const lightOutline = Color(0xFFE1E6F0);
  static const lightText = Color(0xFF111A33);
  static const lightTextMuted = Color(0xFF5E6985);

  // Dark
  static const darkBg = Color(0xFF0B1020);
  static const darkSurface = Color(0xFF121933);
  static const darkSurfaceHigh = Color(0xFF1B2447);
  static const darkOutline = Color(0xFF273157);
  static const darkText = Color(0xFFE9EDFA);
  static const darkTextMuted = Color(0xFF9AA5C8);

  static const star = Color(0xFFF5B400);
  static const success = Color(0xFF1E9E63);
  static const warning = Color(0xFFE08A00);
  static const danger = Color(0xFFD93A32);

  /// Label colour options available to users.
  static const labelPalette = <Color>[
    Color(0xFF1F6BFF),
    Color(0xFF7C3AED),
    Color(0xFFFF7A1A),
    Color(0xFFE5483B),
    Color(0xFF1E9E63),
    Color(0xFF0EA5B7),
    Color(0xFFD6336C),
    Color(0xFF6B7280),
  ];

  /// Deterministic avatar colour from a string.
  static Color avatar(String seed) {
    const palette = <Color>[
      Color(0xFF3B6FE0),
      Color(0xFF7A4FD6),
      Color(0xFFD9692B),
      Color(0xFF1E9E7A),
      Color(0xFFC2416B),
      Color(0xFF0E8FA3),
      Color(0xFF5B6B8C),
      Color(0xFFB4852B),
    ];
    var h = 0;
    for (final c in seed.toLowerCase().codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return palette[h % palette.length];
  }
}
