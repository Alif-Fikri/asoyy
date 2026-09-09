import 'package:flutter/material.dart';

class AppColorTheme extends ThemeExtension<AppColorTheme> {
  final Color background;
  final Color surface;
  final Color card;
  final Color cardLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;

  const AppColorTheme({
    required this.background,
    required this.surface,
    required this.card,
    required this.cardLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
  });

  static const dark = AppColorTheme(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    card: Color(0xFF1C1C1E),
    cardLight: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF98989E),
    textHint: Color(0xFF636366),
    border: Color(0xFF38383A),
    divider: Color(0xFF38383A),
  );

  static const light = AppColorTheme(
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardLight: Color(0xFFE5E5EA),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF6E6E73),
    textHint: Color(0xFFC7C7CC),
    border: Color(0xFFD1D1D6),
    divider: Color(0xFFE5E5EA),
  );

  @override
  AppColorTheme copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? cardLight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? divider,
  }) =>
      AppColorTheme(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        card: card ?? this.card,
        cardLight: cardLight ?? this.cardLight,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textHint: textHint ?? this.textHint,
        border: border ?? this.border,
        divider: divider ?? this.divider,
      );

  @override
  AppColorTheme lerp(AppColorTheme? other, double t) {
    if (other == null) return this;
    return AppColorTheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardLight: Color.lerp(cardLight, other.cardLight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension AppColorContext on BuildContext {
  AppColorTheme get colors => Theme.of(this).extension<AppColorTheme>()!;
}
