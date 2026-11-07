import 'package:flutter/material.dart';
import 'colors.dart';
import 'app_theme.dart';

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AColors.brandBlue,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF6FA0FF),
    onPrimary: const Color(0xFF06143A),
    secondary: const Color(0xFFB095F5),
    tertiary: const Color(0xFFFFA45E),
    surface: AColors.darkBg,
    onSurface: AColors.darkText,
    onSurfaceVariant: AColors.darkTextMuted,
    surfaceContainerLowest: AColors.darkBg,
    surfaceContainerLow: AColors.darkSurface,
    surfaceContainer: AColors.darkSurface,
    surfaceContainerHigh: AColors.darkSurfaceHigh,
    surfaceContainerHighest: AColors.darkSurfaceHigh,
    outline: AColors.darkTextMuted,
    outlineVariant: AColors.darkOutline,
    error: const Color(0xFFFF8A80),
  );
  return AppTheme.compose(scheme, AColors.darkText, AColors.darkTextMuted);
}
