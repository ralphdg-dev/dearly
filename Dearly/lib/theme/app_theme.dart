import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF6B7F5E);
  static const Color primaryDark = Color(0xFF3D4F34);
  static const Color secondary = Color(0xFF9BA893);
  static const Color tertiary = Color(0xFFD9C5B2);
  static const Color neutral = Color(0xFFF7F8F5);
  static const Color neutralDark = Color(0xFFEEEFEB);
  static const Color textDark = Color(0xFF1C1C1C);
  static const Color textMid = Color(0xFF5A5A5A);
  static const Color textLight = Color(0xFF9A9A9A);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color greenChip = Color(0xFFD4E4C8);
  static const Color danger = Color(0xFFD9534F);

  static TextTheme _textTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.notoSerif(fontSize: 32, fontWeight: FontWeight.w700, color: textDark),
      displayMedium: GoogleFonts.notoSerif(fontSize: 26, fontWeight: FontWeight.w700, color: textDark),
      displaySmall: GoogleFonts.notoSerif(fontSize: 22, fontWeight: FontWeight.w600, color: textDark),
      headlineLarge: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
      headlineMedium: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
      headlineSmall: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
      bodyLarge: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w400, color: textDark),
      bodyMedium: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w400, color: textMid),
      bodySmall: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w400, color: textLight),
      labelLarge: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
      labelMedium: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: textMid),
      labelSmall: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: textLight),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: neutral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: neutral,
      textTheme: _textTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: neutral,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.notoSerif(
          fontSize: 16, fontWeight: FontWeight.w600, color: primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: GoogleFonts.manrope(color: textLight, fontSize: 14),
        filled: true,
        fillColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: primary,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: neutralDark,
        selectedColor: greenChip,
        labelStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
      ),
    );
  }
}
