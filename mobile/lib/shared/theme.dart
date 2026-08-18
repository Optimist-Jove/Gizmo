import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GizmoTheme {
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color cardBg = Color(0xFF1E293B); // Slate 800
  static const Color surfaceBg = Color(0xFF334155); // Slate 700
  static const Color accentBlue = Color(0xFF38BDF8); // Sky 400
  static const Color accentAmber = Color(0xFFF59E0B); // Amber 500
  static const Color accentEmerald = Color(0xFF10B981); // Emerald 500
  static const Color accentPurple = Color(0xFFA855F7); // Purple 500
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBg,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentAmber,
        surface: cardBg,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: accentBlue, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
