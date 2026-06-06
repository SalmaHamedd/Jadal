import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debater.dart';

class TeamColors {
  final Color base;
  final Color tint;
  final Color foreground;

  const TeamColors({
    required this.base,
    required this.tint,
    required this.foreground,
  });

  static TeamColors of(TeamSide side, {bool isDark = false}) {
    if (side == TeamSide.government) {
      return TeamColors(
        base: JadalColors.primaryBlue,
        tint: JadalColors.primaryBlue.withValues(alpha: isDark ? 0.22 : 0.12),
        foreground: isDark ? Colors.white : JadalColors.deepBlue,
      );
    }
    return TeamColors(
      base: JadalColors.primaryOrange,
      tint: JadalColors.primaryOrange.withValues(alpha: isDark ? 0.22 : 0.14),
      foreground: isDark ? Colors.white : const Color(0xFF8A3F0E),
    );
  }
}
