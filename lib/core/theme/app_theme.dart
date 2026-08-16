import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTheme {
  static const String _fontFamily = 'Cairo';

  static const Color _lightSurfaceAlt = Color(0xFFF1F4F9);
  static const Color _lightBorder = Color(0xFFD8DEE7);
  static const Color _darkBorder = Color(0xFF2A3A55);
  static const Color _orangeOnDark = Color(0xFFF59A4A);

  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: JadalColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: JadalColors.primaryOrange,
      onSecondary: Colors.white,
      tertiary: JadalColors.deepBlue,
      onTertiary: Colors.white,
      surface: JadalColors.lightSurface,
      onSurface: JadalColors.lightTextPrimary,
      surfaceContainerHighest: _lightSurfaceAlt,
      error: const Color(0xFFD23E3E),
      onError: Colors.white,
      outline: _lightBorder,
      outlineVariant: const Color(0xFFE7ECF2),
    );

    return _build(
      scheme: scheme,
      scaffoldBackground: JadalColors.lightBackground,
      textPrimary: JadalColors.lightTextPrimary,
      textSecondary: JadalColors.lightTextSecondary,
      inputFill: _lightSurfaceAlt,
      borderColor: _lightBorder,
      orangeAccent: JadalColors.primaryOrange,
      systemOverlay: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: JadalColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: _orangeOnDark,
      onSecondary: Colors.black,
      tertiary: JadalColors.deepBlue,
      onTertiary: Colors.white,
      surface: JadalColors.darkSurface,
      onSurface: JadalColors.darkTextPrimary,
      surfaceContainerHighest: JadalColors.darkSurfaceElevated,
      error: const Color(0xFFEF6A6A),
      onError: Colors.black,
      outline: _darkBorder,
      outlineVariant: const Color(0xFF21304A),
    );

    return _build(
      scheme: scheme,
      scaffoldBackground: JadalColors.darkBackground,
      textPrimary: JadalColors.darkTextPrimary,
      textSecondary: JadalColors.darkTextSecondary,
      inputFill: JadalColors.darkSurfaceElevated,
      borderColor: _darkBorder,
      orangeAccent: _orangeOnDark,
      systemOverlay: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color textPrimary,
    required Color textSecondary,
    required Color inputFill,
    required Color borderColor,
    required Color orangeAccent,
    required SystemUiOverlayStyle systemOverlay,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: scaffoldBackground,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      textTheme: _textTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemOverlay,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: true,
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          color: textSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          color: orangeAccent,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: orangeAccent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orangeAccent,
          // White on the brand orange is only 2.84:1, and this is
          // the app's PRIMARY button. Near-black on the same orange is 6.77:1
          // (AAA), so the brand colour is kept exactly and the label changes
          // instead. Dark theme already pairs its lighter orange with black.
          foregroundColor: scheme.brightness == Brightness.dark
              ? Colors.black
              : const Color(0xFF0B0F14),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: orangeAccent,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: orangeAccent,
        linearTrackColor: orangeAccent.withValues(alpha: 0.25),
      ),
      iconTheme: IconThemeData(color: textPrimary),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.brightness == Brightness.dark
            ? JadalColors.darkSurfaceElevated
            : JadalColors.deepBlue,
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          color: textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    // GoogleFonts.cairoTextTheme registers and loads the Cairo font, making
    // fontFamily: 'Cairo' resolve correctly throughout the app.
    return GoogleFonts.cairoTextTheme(TextTheme(
      displayLarge:  TextStyle(fontWeight: FontWeight.w700, fontSize: 32, color: primary),
      displayMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 26, color: primary),
      displaySmall:  TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: primary),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: primary),
      headlineSmall:  TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: primary),
      titleLarge:  TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: primary),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: primary),
      titleSmall:  TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: primary),
      bodyLarge:   TextStyle(fontSize: 15, color: primary,   height: 1.45),
      bodyMedium:  TextStyle(fontSize: 14, color: primary,   height: 1.45),
      bodySmall:   TextStyle(fontSize: 12, color: secondary, height: 1.4),
      labelLarge:  TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: primary),
      labelMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: secondary),
      labelSmall:  TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: secondary),
    ));
  }
}
