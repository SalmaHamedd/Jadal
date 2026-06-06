import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/debate_models.dart';
import 'debate_timeline.dart';

/// Shared Jadal colour helpers for the live-debate UI (§3). Light mode is
/// blue-led with orange reserved for accents/the opposition side; surfaces stay
/// subtle and blue-or-neutral (matching `login_screen.dart`).
abstract class DebateTheme {
  static bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

  static Color background(BuildContext c) =>
      isDark(c) ? JadalColors.darkBackground : JadalColors.lightBackground;

  static Color surface(BuildContext c) =>
      isDark(c) ? JadalColors.darkSurface : JadalColors.lightSurface;

  static Color surfaceElevated(BuildContext c) =>
      isDark(c) ? JadalColors.darkSurfaceElevated : JadalColors.surfaceLight;

  /// Camera-off cards should float as a panel darker than the background (§8.3).
  static Color floatingCard(BuildContext c) => isDark(c)
      ? JadalColors.darkSurfaceElevated
      : Color.lerp(JadalColors.lightBackground, JadalColors.deepBlue, 0.06)!;

  static Color textPrimary(BuildContext c) =>
      isDark(c) ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary;

  static Color textSecondary(BuildContext c) =>
      isDark(c) ? JadalColors.darkTextSecondary : JadalColors.lightTextSecondary;

  static Color sideColor(DebateSide side) => side == DebateSide.proposition
      ? JadalColors.propositionBlue
      : JadalColors.oppositionOrange;

  /// Light/dark-aware gradient for the main card / timer, by speaker side.
  static List<Color> sideGradient(DebateSide side, bool dark) {
    if (side == DebateSide.proposition) {
      return dark
          ? [JadalColors.primaryBlue, JadalColors.deepBlue]
          : [JadalColors.primaryBlue, const Color(0xFF2E6FB8)];
    }
    return dark
        ? [JadalColors.primaryOrange, JadalColors.warmOrange]
        : [JadalColors.primaryOrange, const Color(0xFFC9651A)];
  }

  /// Accent colour for the current timer tier (§8.3 B).
  static Color tierAccent(DebateTier tier, DebateSide side, bool dark) {
    switch (tier) {
      case DebateTier.protected:
        return JadalColors.judgesGrey;
      case DebateTier.open:
        return sideColor(side);
      case DebateTier.extra:
        return const Color(0xFFF5A623); // amber / warning
      case DebateTier.timeOff:
        return const Color(0xFFE53935); // red / error
    }
  }
}
