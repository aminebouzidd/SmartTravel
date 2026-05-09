import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
// Dark theme: "Amber Intelligence" — warm noir terminal
// Light theme: parchment / fieldbook warm whites
class AppPalette {
  // Dark surfaces
  static const bg = Color(0xFF0B0B0E);
  static const surface = Color(0xFF121218);
  static const surfaceRaised = Color(0xFF1A1A24);
  static const border = Color(0xFF202030);

  // Accent
  static const amber = Color(0xFFF0A500);
  static const amberDim = Color(0x28F0A500);
  static const amberGlow = Color(0x12F0A500);

  // Secondary accent
  static const teal = Color(0xFF34D1BF);
  static const tealDim = Color(0x1A34D1BF);

  // States
  static const emerald = Color(0xFF3ECF8E);
  static const errorRed = Color(0xFFEF4444);
  static const violet = Color(0xFF8B8BF0);

  // Text – dark mode
  static const cream = Color(0xFFF0EAD6);
  static const muted = Color(0xFF7C7C9A);
  static const faint = Color(0xFF3A3A50);

  // Light mode surfaces
  static const parchment = Color(0xFFF8F4EC);
  static const parchmentCard = Color(0xFFFFFFFF);
  static const parchmentBorder = Color(0xFFE8E0D0);
  static const inkDark = Color(0xFF1A1008);
  static const inkMuted = Color(0xFF6B5F4A);
  static const amberLight = Color(0xFFD4880A);
}

// ─── Typography ───────────────────────────────────────────────────────────────
class AppFonts {
  // Editorial serif – app name, page titles, hero text
  static TextStyle playfair({
    double size = 32,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  // Technical monospace – labels, codes, status, nav
  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
  }) => GoogleFonts.ibmPlexMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing ?? 0.5,
  );

  // Readable geometric – body text, descriptions
  static TextStyle outfit({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
  }) => GoogleFonts.outfit(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

// ─── Theme Builder ─────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppPalette.bg,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppPalette.amber,
        onPrimary: Color(0xFF0B0B0E),
        secondary: AppPalette.teal,
        onSecondary: Color(0xFF0B0B0E),
        tertiary: AppPalette.emerald,
        onTertiary: Color(0xFF0B0B0E),
        surface: AppPalette.surface,
        onSurface: AppPalette.cream,
        surfaceContainerHighest: AppPalette.surfaceRaised,
        outline: AppPalette.border,
        outlineVariant: AppPalette.faint,
        error: AppPalette.errorRed,
      ),
      textTheme: _darkTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.bg,
        foregroundColor: AppPalette.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppFonts.mono(
          size: 13,
          weight: FontWeight.w600,
          color: AppPalette.cream,
          letterSpacing: 2.0,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppPalette.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.border,
        thickness: 1,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface,
        hintStyle: AppFonts.outfit(size: 14, color: AppPalette.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.amber, width: 1.5),
        ),
        prefixIconColor: AppPalette.muted,
        suffixIconColor: AppPalette.muted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppPalette.amber
              : AppPalette.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppPalette.amberDim
              : AppPalette.border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.surfaceRaised,
        contentTextStyle: AppFonts.outfit(color: AppPalette.cream, size: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppPalette.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.surface,
        indicatorColor: AppPalette.amberDim,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppPalette.amber
                : AppPalette.muted,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppFonts.mono(
            size: 10,
            color: s.contains(WidgetState.selected)
                ? AppPalette.amber
                : AppPalette.muted,
          ),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppPalette.parchment,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppPalette.amberLight,
        onPrimary: Colors.white,
        secondary: Color(0xFF0EA5A0),
        onSecondary: Colors.white,
        tertiary: Color(0xFF16A34A),
        surface: AppPalette.parchmentCard,
        onSurface: AppPalette.inkDark,
        surfaceContainerHighest: Color(0xFFF0EAE0),
        outline: AppPalette.parchmentBorder,
        error: AppPalette.errorRed,
      ),
      textTheme: _lightTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.parchment,
        foregroundColor: AppPalette.inkDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppFonts.mono(
          size: 13,
          weight: FontWeight.w600,
          color: AppPalette.inkDark,
          letterSpacing: 2.0,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.parchmentCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppPalette.parchmentBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.parchmentBorder,
        thickness: 1,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.parchmentCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.parchmentBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.parchmentBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppPalette.amberLight,
            width: 1.5,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.inkDark,
        contentTextStyle: AppFonts.outfit(color: AppPalette.cream, size: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _darkTextTheme() {
    return TextTheme(
      displayLarge: AppFonts.playfair(
        size: 48,
        color: AppPalette.cream,
        letterSpacing: -1.5,
      ),
      headlineLarge: AppFonts.playfair(size: 32, color: AppPalette.cream),
      headlineMedium: AppFonts.playfair(
        size: 24,
        weight: FontWeight.w600,
        color: AppPalette.cream,
      ),
      titleLarge: AppFonts.outfit(
        size: 20,
        weight: FontWeight.w600,
        color: AppPalette.cream,
      ),
      titleMedium: AppFonts.outfit(
        size: 16,
        weight: FontWeight.w600,
        color: AppPalette.cream,
      ),
      titleSmall: AppFonts.mono(
        size: 12,
        weight: FontWeight.w600,
        color: AppPalette.amber,
        letterSpacing: 1.2,
      ),
      bodyLarge: AppFonts.outfit(
        size: 16,
        color: AppPalette.cream,
        height: 1.6,
      ),
      bodyMedium: AppFonts.outfit(
        size: 14,
        color: AppPalette.cream,
        height: 1.5,
      ),
      bodySmall: AppFonts.outfit(
        size: 12,
        color: AppPalette.muted,
        height: 1.4,
      ),
      labelLarge: AppFonts.mono(
        size: 13,
        weight: FontWeight.w600,
        color: AppPalette.cream,
        letterSpacing: 0.8,
      ),
      labelMedium: AppFonts.mono(
        size: 11,
        weight: FontWeight.w500,
        color: AppPalette.muted,
        letterSpacing: 0.6,
      ),
      labelSmall: AppFonts.mono(
        size: 10,
        color: AppPalette.muted,
        letterSpacing: 1.2,
      ),
    );
  }

  static TextTheme _lightTextTheme() {
    return TextTheme(
      displayLarge: AppFonts.playfair(
        size: 48,
        color: AppPalette.inkDark,
        letterSpacing: -1.5,
      ),
      headlineLarge: AppFonts.playfair(size: 32, color: AppPalette.inkDark),
      headlineMedium: AppFonts.playfair(
        size: 24,
        weight: FontWeight.w600,
        color: AppPalette.inkDark,
      ),
      titleLarge: AppFonts.outfit(
        size: 20,
        weight: FontWeight.w600,
        color: AppPalette.inkDark,
      ),
      titleMedium: AppFonts.outfit(
        size: 16,
        weight: FontWeight.w600,
        color: AppPalette.inkDark,
      ),
      titleSmall: AppFonts.mono(
        size: 12,
        weight: FontWeight.w600,
        color: AppPalette.amberLight,
        letterSpacing: 1.2,
      ),
      bodyLarge: AppFonts.outfit(
        size: 16,
        color: AppPalette.inkDark,
        height: 1.6,
      ),
      bodyMedium: AppFonts.outfit(
        size: 14,
        color: AppPalette.inkDark,
        height: 1.5,
      ),
      bodySmall: AppFonts.outfit(
        size: 12,
        color: AppPalette.inkMuted,
        height: 1.4,
      ),
      labelLarge: AppFonts.mono(
        size: 13,
        weight: FontWeight.w600,
        color: AppPalette.inkDark,
        letterSpacing: 0.8,
      ),
      labelMedium: AppFonts.mono(
        size: 11,
        weight: FontWeight.w500,
        color: AppPalette.inkMuted,
        letterSpacing: 0.6,
      ),
      labelSmall: AppFonts.mono(
        size: 10,
        color: AppPalette.inkMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}
