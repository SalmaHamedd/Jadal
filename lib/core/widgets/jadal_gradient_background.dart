import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The shared backdrop for the live-debate (and statistics) screens: a single,
/// very soft diagonal wash that starts and ends on the scaffold colour and only
/// drifts a hair toward the brand blue / deep-blue / orange in between.
///
/// Key points (so it never fights the content on top of it):
///  • Every stop is **opaque** — the colours are the base blended a little toward
///    a brand colour, not translucent overlays — so there are no see-through gaps
///    (that was the "black in the middle" bug) and it works whether it sits over a
///    Scaffold or wraps one.
///  • Both ends are exactly the base colour, so the wash melts seamlessly into the
///    rest of the UI with no hard "cut" between the tint and the background.
///  • The blend factors are deliberately tiny → subtle, not childish, and it never
///    overshadows the cards/sheets layered above it.
class JadalGradientBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const JadalGradientBackground({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? JadalColors.darkBackground : JadalColors.lightBackground;

    // Opaque tint = base nudged toward a brand colour by [t] (kept small).
    Color tint(Color c, double t) => Color.lerp(base, c, t)!;

    // Dark needs a touch more lift to be perceptible against the navy base.
    final tBlue = isDark ? 0.14 : 0.06;
    final tDeep = isDark ? 0.16 : 0.05;
    final tOrange = isDark ? 0.12 : 0.06;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            tint(JadalColors.primaryBlue, tBlue),
            tint(JadalColors.deepBlue, tDeep),
            tint(JadalColors.primaryOrange, tOrange),
            base,
          ],
          // Generous shoulders on the base so the colour only lives in the middle
          // and eases in/out gently.
          stops: const [0.0, 0.30, 0.52, 0.74, 1.0],
        ),
      ),
      child: padding == EdgeInsets.zero ? child : Padding(padding: padding, child: child),
    );
  }
}
