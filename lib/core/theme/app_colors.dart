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

  static const Color judgesGrey = Color(0xFF9A9A9A);

  static const Color judgesGreyLight = Color(0xFF636B76);

  static const Color positiveGreen = Color(0xFF1FA463);
  static const Color negativeRed   = Color(0xFFB3261E);

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

