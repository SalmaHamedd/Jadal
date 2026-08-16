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
  ///
  /// Brand blue and orange hold slots 1–2 so charts still read as Jadal; the
  /// rest are chosen to stay distinguishable under colour-blindness, which the
  /// old orange/gold and blue/deep-blue pairs were not. Charts with six or more
  /// series should add a fill pattern rather than a ninth hue.
  static const List<Color> seriesColors = [
    JadalColors.primaryBlue,   // #0352A1
    JadalColors.primaryOrange, // #EA7C1C
    Color(0xFF009E73), // teal-green
    Color(0xFFCC79A7), // magenta
    Color(0xFF56B4E9), // sky blue
    Color(0xFF4C4C4C), // slate
    Color(0xFF785EF0), // violet
    Color(0xFF9C1B32), // crimson
  ];

  static Color seriesColor(int index) =>
      seriesColors[index % seriesColors.length];
}

/// The app's second-signal helper for signed values.
/// Colour must never be the only carrier of meaning: under red–green
/// colour-vision deficiency (the most common kind) a "good" green and a "bad"
/// red converge, and in greyscale they are identical. Prefixing an arrow and an
/// explicit sign makes the direction readable without any colour at all.
/// Rule for new code: if a widget branches a **colour** on state, it must
/// branch a **glyph or label** on the same state in the same commit.
String signedWithArrow(double v, {int decimals = 1}) {
  final arrow = v > 0
      ? '▲ '
      : v < 0
      ? '▼ '
      : '';
  final sign = v >= 0 ? '+' : '';
  return '$arrow$sign${v.toStringAsFixed(decimals)}';
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
            // Center keeps the label vertically centred even when a
            // fixed-height list stretches the chip taller than its content.
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
