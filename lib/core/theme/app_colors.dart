import 'package:flutter/material.dart';

/// Theme extension that provides semantic colors for the app.
/// Widgets access these via `Theme.of(context).extension<AppColorsExtension>()!`.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color surface;
  final Color card;
  final Color accent;
  final Color accentSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color iconInactive;
  final Color sliderInactive;
  final Color error;
  final Color success;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.card,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.iconInactive,
    required this.sliderInactive,
    required this.error,
    required this.success,
  });

  /// Light palette
  static const light = AppColorsExtension(
    background: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFF1F2F8),
    accent: Color(0xFF7C6CFF),
    accentSoft: Color(0xFF9B8CFF),
    textPrimary: Color(0xFF0E0E11),
    textSecondary: Color(0xFF55566B),
    textDisabled: Color(0xFF9A9AB0),
    iconInactive: Color(0xFF7A7A90),
    sliderInactive: Color(0xFFE0E1EA),
    error: Color(0xFFFF4D4D),
    success: Color(0xFF4ADE80),
  );

  /// Dark palette
  static const dark = AppColorsExtension(
    background: Color(0xFF121218),
    surface: Color(0xFF1E1E2A),
    card: Color(0xFF272736),
    accent: Color(0xFF9B8CFF),
    accentSoft: Color(0xFF7C6CFF),
    textPrimary: Color(0xFFE8E8F0),
    textSecondary: Color(0xFFA0A0B8),
    textDisabled: Color(0xFF606078),
    iconInactive: Color(0xFF7A7A90),
    sliderInactive: Color(0xFF3A3A4E),
    error: Color(0xFFFF6B6B),
    success: Color(0xFF4ADE80),
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? accent,
    Color? accentSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? iconInactive,
    Color? sliderInactive,
    Color? error,
    Color? success,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      iconInactive: iconInactive ?? this.iconInactive,
      sliderInactive: sliderInactive ?? this.sliderInactive,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      iconInactive: Color.lerp(iconInactive, other.iconInactive, t)!,
      sliderInactive: Color.lerp(sliderInactive, other.sliderInactive, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

/// Convenience extension on BuildContext to access app colors quickly.
extension AppColorsContext on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
