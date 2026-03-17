import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors from index.css and tailwind.config.ts
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0F172A); // slate-900
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF0F172A);
  static const Color popover = Color(0xFFFFFFFF);
  static const Color popoverForeground = Color(0xFF0F172A);
  static const Color primary = Color(0xFF000000); // Black
  static const Color primaryForeground = Color(0xFFF8FAFC); // slate-50
  static const Color secondary = Color(0xFFF1F5F9); // slate-100
  static const Color secondaryForeground = Color(0xFF0F172A);
  static const Color muted = Color(0xFFF1F5F9); // slate-100
  static const Color mutedForeground = Color(0xFF64748B); // slate-500
  static const Color accent = Color(0xFFF1F5F9); // slate-100
  static const Color accentForeground = Color(0xFF0F172A);
  static const Color destructive = Color(0xFFEF4444); // red-500
  static const Color destructiveForeground = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color input = Color(0xFFE2E8F0);
  static const Color ring = Color(0xFF000000); // Black

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: primaryForeground,
      secondary: secondary,
      onSecondary: secondaryForeground,
      error: destructive,
      onError: destructiveForeground,
      surface: card,
      onSurface: foreground,
      outline: border,
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: foreground,
      displayColor: foreground,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: ring, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ).copyWith(inherit: false), // Match Material 3 default for labelLarge to prevent interpolation errors
      ),
    ),
  );
}
