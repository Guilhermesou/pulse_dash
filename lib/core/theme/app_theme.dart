import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppAccentColor {
  final String name;
  final Color color;
  const AppAccentColor(this.name, this.color);
}

class AppTheme {
  static const Color pulseRed = Color(0xFFE3000F);
  static const Color backgroundBlack = Color(0xFF0D0D0D);
  static const Color cardGray = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFF888888);

  static const List<AppAccentColor> accentColors = [
    AppAccentColor('Vermelho GTI', Color(0xFFE3000F)),
    AppAccentColor('Azul', Color(0xFF2196F3)),
    AppAccentColor('Verde', Color(0xFF00E676)),
    AppAccentColor('Laranja', Color(0xFFFF6F00)),
    AppAccentColor('Roxo', Color(0xFF9C27B0)),
    AppAccentColor('Ciano', Color(0xFF00BCD4)),
    AppAccentColor('Branco', Color(0xFFF5F5F5)),
  ];

  static ThemeData buildTheme(Color primary) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundBlack,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: cardGray,
        onPrimary: Colors.white,
        onSurface: textLight,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: textLight, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: textLight, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: textLight, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: textLight),
        bodyMedium: const TextStyle(color: textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardGray,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => buildTheme(pulseRed);
}
