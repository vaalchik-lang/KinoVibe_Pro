// theme/app_theme.dart — Tropical Noir / Steampunk Bronze
// Palette: #0A0810 / #B87333 / #D4A843 / #C9924A / #4A7A6B

import 'package:flutter/material.dart';

class KinoColors {
  static const background = Color(0xFF0A0810);
  static const bronze     = Color(0xFFB87333);
  static const gold       = Color(0xFFD4A843);
  static const copper     = Color(0xFFC9924A);
  static const patina     = Color(0xFF4A7A6B);

  // Вспомогательные
  static const surface    = Color(0xFF12101A);
  static const cardBg     = Color(0xFF1A1624);
  static const textPrimary   = Color(0xFFE8D5B0);
  static const textSecondary = Color(0xFF8A7560);
  static const divider    = Color(0xFF2A2035);
}

class KinoTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: KinoColors.background,
    colorScheme: const ColorScheme.dark(
      primary:   KinoColors.bronze,
      secondary: KinoColors.gold,
      surface:   KinoColors.surface,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: KinoColors.gold,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
      bodyLarge: TextStyle(color: KinoColors.textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: KinoColors.textSecondary, fontSize: 14),
    ),
    iconTheme: const IconThemeData(color: KinoColors.bronze),
  );
}

// Градиент: бронзовое свечение сверху-слева (30°)
class KinoGradients {
  static const bronzeGlow = RadialGradient(
    center: Alignment(-0.7, -0.7),
    radius: 1.5,
    colors: [Color(0x40B87333), Color(0x00000000)],
  );

  static const cardShine = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x30D4A843), Color(0x00000000)],
  );
}
