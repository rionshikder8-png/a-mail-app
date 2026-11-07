import 'package:flutter/material.dart';

class ATypography {
  ATypography._();

  static TextTheme textTheme(Color text, Color muted) {
    TextStyle s(double size, FontWeight w, {double? h, double ls = 0, Color? c}) =>
        TextStyle(fontSize: size, fontWeight: w, height: h, letterSpacing: ls, color: c ?? text);
    return TextTheme(
      displaySmall: s(34, FontWeight.w700, h: 1.15, ls: -0.8),
      headlineMedium: s(26, FontWeight.w700, h: 1.2, ls: -0.4),
      headlineSmall: s(22, FontWeight.w700, h: 1.25, ls: -0.2),
      titleLarge: s(20, FontWeight.w600, h: 1.3),
      titleMedium: s(16, FontWeight.w600, h: 1.35),
      titleSmall: s(14, FontWeight.w600, h: 1.35),
      bodyLarge: s(16, FontWeight.w400, h: 1.5),
      bodyMedium: s(14, FontWeight.w400, h: 1.45),
      bodySmall: s(12, FontWeight.w400, h: 1.4, c: muted),
      labelLarge: s(14, FontWeight.w600, ls: 0.1),
      labelMedium: s(12, FontWeight.w600, ls: 0.2),
      labelSmall: s(11, FontWeight.w600, ls: 0.3, c: muted),
    );
  }
}
