import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;
  double wp(double percent) => screenWidth * (percent / 100);
  double hp(double percent) => screenHeight * (percent / 100);
  double fontSize(double baseSize, {double? min, double? max}) {
    double scaled = baseSize * (screenWidth / 375);
    if (min != null && scaled < min) scaled = min;
    if (max != null && scaled > max) scaled = max;
    return scaled;
  }
  double spacing(double baseSize) => baseSize * (screenWidth / 375);
}
