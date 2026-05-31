import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CoinNest Design System — derived from Stitch project tokens.
/// Font: Be Vietnam Pro | Roundness: 16 px | Color Mode: Light
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF00668A);
  static const Color primaryContainer = Color(0xFF29ABE2);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF003B53);

  // Income / positive
  static const Color secondary = Color(0xFF006E1C);
  static const Color secondaryContainer = Color(0xFF91F78E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF00731E);

  // Expense / negative
  static const Color tertiary = Color(0xFFBB1614);
  static const Color tertiaryContainer = Color(0xFFFF7666);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF750003);

  // Surfaces
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceDim = Color(0xFFDADADA);

  // On-surface
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF3E484F);

  // Outline
  static const Color outline = Color(0xFF6E7880);
  static const Color outlineVariant = Color(0xFFBDC8D0);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Inverse
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);
  static const Color inversePrimary = Color(0xFF7BD0FF);

  // ─── Semantic Aliases ──────────────────────────────────────────
  static const Color incomeColor = secondary;
  static const Color expenseColor = tertiary;
  static const Color transferColor = primary;
  static const Color loanColor = Color(0xFF8A5100);
  static const Color warningColor = Color(0xFF750003);

  // ─── Spacing Scale ─────────────────────────────────────────────
  static const double spacing2 = 4;
  static const double spacing4 = 8;
  static const double spacing6 = 12;
  static const double spacing8 = 16;
  static const double spacing10 = 20;
  static const double spacing12 = 24;
  static const double spacing16 = 32;
  static const double spacing20 = 40;
  static const double spacing24 = 48;

  // ─── Radii ─────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ─── Light Theme ───────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = _textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        onSecondary: onSecondary,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiary: onTertiary,
        onTertiaryContainer: onTertiaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        error: error,
        errorContainer: errorContainer,
        onError: onError,
        onErrorContainer: onErrorContainer,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverseSurface,
        onInverseSurface: inverseOnSurface,
        inversePrimary: inversePrimary,
      ),

      scaffoldBackgroundColor: surface,

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainerLowest,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
      ),

      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(
        backgroundColor:
            surfaceContainerLowest,
        selectedItemColor: primary,
        unselectedItemColor: outline,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(radiusLg),
        ),
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(radiusLg),
          ),
        ),
      ),

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,
        fillColor:
            surfaceContainerHighest,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(radiusMd),
          borderSide:
              const BorderSide(
            color: primary,
            width: 2,
          ),
        ),
      ),

      textTheme: textTheme,
    );
  }

  // ─── Dark Theme ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final textTheme = _textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: primaryContainer,
        secondary: secondaryContainer,
        tertiary: tertiaryContainer,

        surface: Color(0xFF121212),

        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFB0B0B0),

        outline: Color(0xFF5F6368),
        outlineVariant: Color(0xFF3C4043),

        error: error,
      ),

      scaffoldBackgroundColor:
          const Color(0xFF121212),

      appBarTheme: AppBarTheme(
        backgroundColor:
            const Color(0xFF121212),

        foregroundColor: Colors.white,

        elevation: 0,

        titleTextStyle:
            textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),

        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(radiusLg),
        ),
      ),

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,

        fillColor:
            const Color(0xFF1E1E1E),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(radiusMd),

          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(radiusMd),

          borderSide: BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(radiusMd),

          borderSide:
              const BorderSide(
            color: primaryContainer,
            width: 2,
          ),
        ),

        hintStyle: TextStyle(
          color: Colors.white.withAlpha(120),
        ),

        labelStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              primaryContainer,

          foregroundColor: Colors.white,

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              radiusLg,
            ),
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withAlpha(30),
        thickness: 1,
        space: 0,
      ),

      bottomSheetTheme:
          const BottomSheetThemeData(
        backgroundColor:
            Color(0xFF1E1E1E),

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            const Color(0xFF2A2A2A),

        contentTextStyle:
            textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
      ),

      textTheme: textTheme,
    );
  }

  // ─── Typography ────────────────────────────────────────────────
  static TextTheme get _textTheme {
    return GoogleFonts.beVietnamProTextTheme(
      const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),

        bodyLarge: TextStyle(
          fontSize: 16,
          color: onSurface,
        ),

        bodyMedium: TextStyle(
          fontSize: 14,
          color: onSurface,
        ),

        bodySmall: TextStyle(
          fontSize: 12,
          color: onSurfaceVariant,
        ),

        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
    );
  }
}