import 'package:flutter/material.dart';
import 'colors.dart';
import 'app_theme.dart';

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AColors.brandBlue,
    brightness: Brightness.light,
  ).copyWith(
    primary: AColors.brandBlue,
    onPrimary: Colors.white,
    secondary: AColors.brandViolet,
    tertiary: AColors.brandOrange,
    surface: AColors.lightBg,
    onSurface: AColors.lightText,
    onSurfaceVariant: AColors.lightTextMuted,
    surfaceContainerLowest: AColors.lightBg,
    surfaceContainerLow: AColors.lightSurface,
    surfaceContainer: AColors.lightSurface,
    surfaceContainerHigh: AColors.lightSurfaceHigh,
    surfaceContainerHighest: AColors.lightSurfaceHigh,
    outline: AColors.lightTextMuted,
    outlineVariant: AColors.lightOutline,
    error: AColors.danger,
  );
  return AppTheme.compose(scheme, AColors.lightText, AColors.lightTextMuted);
}
