import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_accent_theme.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light([AppAccentTheme? accent]) {
    final a = accent ?? AppAccentTheme.defaultTheme();
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: a.primary,
        secondary: a.secondary,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSurface: const Color(0xFF1A1A2E),
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightCard,
      dividerColor: const Color(0xFFE8E9F3),
      extensions: [a],
    );
    return _apply(base, isDark: false, accent: a);
  }

  static ThemeData dark([AppAccentTheme? accent]) {
    final a = accent ?? AppAccentTheme.defaultTheme();
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: a.primaryLight,
        secondary: a.secondary,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
        onSurface: const Color(0xFFE8E9F3),
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCard,
      dividerColor: const Color(0xFF2A2A45),
      extensions: [a],
    );
    return _apply(base, isDark: true, accent: a);
  }

  static ThemeData _apply(ThemeData base, {required bool isDark, required AppAccentTheme accent}) {
    return base.copyWith(
      textTheme: _textTheme(base.textTheme, isDark: isDark),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? const Color(0xFFE8E9F3) : const Color(0xFF1A1A2E),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFE8E9F3) : const Color(0xFF1A1A2E),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E35) : const Color(0xFFF0F1F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: isDark ? const Color(0xFF6B6B8A) : const Color(0xFF9E9EB8),
          fontSize: 15,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: accent.primary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        selectedItemColor: accent.primary,
        unselectedItemColor: isDark ? const Color(0xFF6B6B8A) : const Color(0xFF9E9EB8),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, {required bool isDark}) {
    final color = isDark ? const Color(0xFFE8E9F3) : const Color(0xFF1A1A2E);
    final muted = isDark ? const Color(0xFF9E9EB8) : const Color(0xFF6B6B8A);
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
