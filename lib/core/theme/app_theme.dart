import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData _buildTheme(
    AppColorsExtension colors,
    Brightness brightness,
  ) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        secondary: colors.accentSoft,
        surface: colors.surface,
        error: colors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: colors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: colors.textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: colors.textDisabled, fontSize: 12),
      ),
      iconTheme: IconThemeData(color: colors.iconInactive),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.surface,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accent,
        inactiveTrackColor: colors.sliderInactive,
        thumbColor: colors.accent,
        overlayColor: colors.accent.withValues(alpha: 0.12),
      ),
      extensions: [colors],
    );
  }

  static ThemeData get lightTheme =>
      _buildTheme(AppColorsExtension.light, Brightness.light);

  static ThemeData get darkTheme =>
      _buildTheme(AppColorsExtension.dark, Brightness.dark);

  const AppTheme._();
}
