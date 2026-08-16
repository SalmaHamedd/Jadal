import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The shared backdrop for the live-debate and statistics screens: a soft
/// diagonal wash that starts and ends on the scaffold colour and drifts only
/// slightly toward the brand colours in between.
///
/// Every stop is opaque (the base blended toward a brand colour, not a
/// translucent overlay) so the wash works over a Scaffold or wrapping one, and
/// both ends match the base colour so it blends into the rest of the UI.
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

    // Dark gets a touch more presence; light gets a bit more still (it was so
    // faint you had to look for it). Orange is nudged the least in dark since it
    // already reads brightest there.
    final tBlue = isDark ? 0.17 : 0.10;
    final tDeep = isDark ? 0.19 : 0.09;
    final tOrange = isDark ? 0.13 : 0.10;

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
