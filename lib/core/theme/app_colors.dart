import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color lightRed = Color(0xffc65b5b);
  static const Color darkRed = Color(0xff8C3A3A);
  static const Color lightBlue = Color(0xff728CAC);
  static const Color darkBlue = Color(0xff325985);
  static const Color mainDark = Color(0xff1f2635);
  static const Color mainLight = Color(0xffe8e7f1);
  static const Color lighterColor = Color(0xfff1f0fa);
  static const Color lighterDarkColor = Color(0xff2D3748);
  static const Color blackColor = Color.fromRGBO(12, 16, 27, 1.0);
  static const Color medium = Color(0xff9A9A9A);
  static const Color light = Color(0xffCDCDCD);
  static const Color white = Color(0xffffffff);
  static const Color lightGreen = Color(0xff439a5d);

  static Color getSideColor(String side){
    if(side == "og") return lightBlue;
    if(side == "oo") return lightRed;
    if(side == "cg") return darkBlue;
    return darkRed;
  }
}

class ThemedColors {
  late Color primary;
  late Color secondary;
  late Color red;
  late Color blue;
  late Color darkerOrLighter;

  ThemedColors(bool isLightTheme){
    primary = isLightTheme ? AppColors.mainLight : AppColors.mainDark;
    secondary = isLightTheme ? AppColors.mainDark : AppColors.mainLight;
    red = isLightTheme ? AppColors.darkRed : AppColors.lightRed;
    blue = isLightTheme ? AppColors.darkBlue : AppColors.lightBlue;
    darkerOrLighter = isLightTheme ? AppColors.lighterColor : AppColors.lighterDarkColor;
  }
}

const Color errorColor = Color.fromRGBO(218, 27, 27, 1.0);
const Color brightRedColor = Color.fromRGBO(240, 67, 73, 1.0);
const Color successColor = Color.fromRGBO(37, 152, 62, 1.0);
const Color brightGreenColor = Color.fromRGBO(1, 225, 123, 1.0);

abstract class JadalColors {
  // Core brand colors
  static const Color primaryBlue    = Color(0xFF0352A1);
  static const Color primaryOrange  = Color(0xFFEA7C1C);
  static const Color deepBlue       = Color(0xFF1A3868);
  static const Color warmOrange     = Color(0xFF895541);
  // Semantic aliases (proposition = blue, opposition = orange)
  static const Color propositionBlue  = Color(0xFF0352A1);
  static const Color oppositionOrange = Color(0xFFEA7C1C);
  static const Color propositionColor = Color(0xFF0352A1);
  static const Color oppositionColor  = Color(0xFFEA7C1C);
  // Neutral. `judgesGrey` is tuned for the DARK ground (5.39:1 there); on the
  // light ground it only reaches 2.62:1, below even the 3:1 non-text floor, so
  // light surfaces use [judgesGreyLight] (4.50:1) instead. Route through
  // DebateTheme/StatsTheme.textSecondary or jadalTextSecondary where possible.
  static const Color judgesGrey = Color(0xFF9A9A9A);
  /// 5.02:1 on `lightBg`, 5.39:1 on white — clear of the 4.5 AA floor rather
  /// than sitting exactly on it.
  static const Color judgesGreyLight = Color(0xFF636B76);
  // Positive / negative accents, tuned to sit beside the brand blue & orange.
  // `negativeRed` was #D84857, which under simulated deuteranopia
  // (the most common colour-vision deficiency) landed at CIEDE2000 ΔE 4.6 from
  // positiveGreen: both collapse to the same olive (#8D8D66 vs #888851), with
  // only a 1.08:1 luminance ratio between them, so win/loss, accept/reject and
  // every ± delta were indistinguishable. #B3261E scores ΔE 17.4 / 31.8 / 55.7
  // across deutan/protan/tritan against the UNCHANGED green, and lifts its own
  // contrast on white from 4.21:1 to 6.54:1. Colour is still never the only
  // signal — see the arrow/sign rule in the stats views.
  static const Color positiveGreen = Color(0xFF1FA463);
  static const Color negativeRed   = Color(0xFFB3261E);
  /// White-on-green fails contrast at [positiveGreen] (3.21:1); this darker
  /// green is used only where green is a BUTTON FILL under white text (5.34:1).
  static const Color positiveGreenFill = Color(0xFF137A52);
  // Light theme
  static const Color lightBg            = Color(0xFFFBF6F0);
  static const Color lightBackground    = Color(0xFFFBF6F0);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightTextPrimary   = Color(0xFF1A3868);
  static const Color lightTextSecondary = Color(0xFF5A7296);
  static const Color surfaceLight       = Color(0xFFF8F9FA);
  // Dark theme
  static const Color darkBackground      = Color(0xFF0D1B2E);
  static const Color darkSurface         = Color(0xFF162640);
  static const Color darkSurfaceElevated = Color(0xFF1E3250);
  static const Color darkTextPrimary     = Color(0xFFF0F4FA);
  static const Color darkTextSecondary   = Color(0xFF8BA5C8);
  static const Color surfaceDark         = Color(0xFF2D3748);
  static const Color cardBackgroundDark  = Color(0xFF1E2532);
}

