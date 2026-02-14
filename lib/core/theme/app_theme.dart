import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      secondary: AppColors.accentSoft,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textDisabled, fontSize: 12),
    ),
    iconTheme: const IconThemeData(color: AppColors.iconInactive),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.sliderInactive,
      thumbColor: AppColors.accent,
      overlayColor: AppColors.accent.withValues(alpha: 0.12),
    ),
  );

  const AppTheme._();
}
