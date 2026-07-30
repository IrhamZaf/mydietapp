import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean, modern light look: vivid blue primary, soft blue-grey surfaces,
/// rounded cards, Inter type. Matches the dashboard mockup.
class AppTheme {
  static const Color primaryBlue = Color(0xFF2F6BFF);
  static const Color primaryDarkBlue = Color(0xFF1E4FD6);

  // Legacy aliases (older screens reference these names)
  static const Color primaryEmerald = primaryBlue;
  static const Color primaryDarkEmerald = primaryDarkBlue;
  static const Color secondaryTeal = Color(0xFF4C8DFF);

  static const Color accentCoral = Color(0xFFFF7A59);
  static const Color accentBlue = primaryBlue;
  static const Color accentOrange = Color(0xFFF5A623);
  static const Color accentPurple = Color(0xFF9B8CFF);
  static const Color accentPink = Color(0xFFFF6B9D);

  // Macro colors (mockup: protein green, carbs blue, fat orange)
  static const Color macroProtein = Color(0xFF22C55E);
  static const Color macroCarbs = Color(0xFF3B82F6);
  static const Color macroFat = Color(0xFFF5A623);

  static const Color accentOrangeLegacy = accentOrange;

  static const Color lightBackground = Color(0xFFF3F6FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6EBF4);
  static const Color lightTextPrimary = Color(0xFF16233A);
  static const Color lightTextSecondary = Color(0xFF7B8BA3);
  static const Color lightInputFill = Color(0xFFEEF2FA);

  static const Color darkBackground = Color(0xFF0E1626);
  static const Color darkSurface = Color(0xFF16233A);
  static const Color darkCard = Color(0xFF1E2E4A);
  static const Color darkTextPrimary = Color(0xFFF3F6FC);
  static const Color darkTextSecondary = Color(0xFF9BAAC4);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF16233A).withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        onPrimary: Colors.white,
        secondary: accentOrange,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: Color(0xFFFF5C5C),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
          letterSpacing: -0.6,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: lightTextPrimary,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: lightTextSecondary,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputFill,
        hintStyle: GoogleFonts.inter(color: lightTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF5C5C), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: lightTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        onPrimary: Colors.white,
        secondary: accentOrange,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: Color(0xFFFF5C5C),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: darkTextPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800, color: darkTextPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: darkTextPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: darkTextPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
