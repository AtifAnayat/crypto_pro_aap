import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF252525);
  static const Color accent = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);

  static ThemeData get premiumDarkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accent,
        surface: surfaceDark,
        background: backgroundDark,
        error: accentRed,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        bodySmall: TextStyle(color: Colors.white70),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.white60),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
