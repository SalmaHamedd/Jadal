import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Small shared theming helpers for the statistics screens so every card, chip
/// and chart pulls from the same on-brand palette and adapts to light/dark.
class StatsTheme {
  StatsTheme._();

  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color surface(BuildContext c) =>
      isDark(c) ? JadalColors.darkSurfaceElevated : JadalColors.lightSurface;

  static Color textPrimary(BuildContext c) =>
      isDark(c) ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary;

  static Color textSecondary(BuildContext c) => isDark(c)
      ? JadalColors.darkTextSecondary
      : JadalColors.lightTextSecondary;

  static Color border(BuildContext c) => isDark(c)
      ? Colors.white.withValues(alpha: 0.07)
      : JadalColors.primaryBlue.withValues(alpha: 0.08);

  /// A distinct, on-brand colour per series index (cycles).
  static const List<Color> seriesColors = [
    JadalColors.primaryBlue,
    JadalColors.primaryOrange,
    JadalColors.deepBlue,
    Color(0xFF2E9E5B), // green
    Color(0xFF8E5BD6), // violet
    Color(0xFF17A2B8), // teal
    Color(0xFFE0567E), // pink
    Color(0xFFB8860B), // gold
  ];

  static Color seriesColor(int index) =>
      seriesColors[index % seriesColors.length];
}

/// A rounded elevated card used to frame chart / list sections, matching the
/// live-debate detail's `_Section` look.
class StatsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const StatsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final dark = StatsTheme.isDark(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: StatsTheme.surface(
          context,
        ).withValues(alpha: dark ? 0.85 : 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StatsTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.06),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A pill toggle chip used throughout the filter bar / selectors.
class StatsChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color? accent;
  final VoidCallback? onTap;
  const StatsChip({
    super.key,
    required this.label,
    required this.selected,
    this.enabled = true,
    this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? JadalColors.primaryOrange;
    final dark = StatsTheme.isDark(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: Material(
        color: selected
            ? color
            : (dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: enabled ? onTap : null,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: AppTextStyles.body(context).copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? Colors.white
                  : enabled
                  ? StatsTheme.textSecondary(context)
                  : StatsTheme.textSecondary(context).withValues(alpha: 0.4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
