import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';


class JadalBlobBackground extends StatelessWidget {
  final Widget child;
  final bool fillBackground;

  const JadalBlobBackground({
    super.key,
    required this.child,
    this.fillBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Each position keeps the SAME hue in light and dark (only the alpha lifts a
    // little in dark so it stays visible) — so a spot that's orange stays orange
    // in both themes. The two brand colours alternate across many small blobs
    // instead of one big orange top / blue bottom.
    // Centre alpha a touch higher than before since the radial gradient now fades
    // each blob to nothing at its edge (net intensity stays close to the look you
    // liked, just softer-edged).
    final blue = JadalColors.primaryBlue.withValues(alpha: isDark ? 0.18 : 0.15);
    final orange = JadalColors.primaryOrange.withValues(alpha: isDark ? 0.17 : 0.14);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (fillBackground)
          ColoredBox(
            color: isDark ? JadalColors.darkBackground : JadalColors.lightBackground,
          ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              // Smaller base than before; each blob scales off it.
              final s = (w * 0.46).clamp(130.0, 210.0);
              // (topFraction, leftFraction, colour, sizeScale) — adjacent blobs
              // alternate colour so the two hues weave down the screen.
              final blobs = <(double, double, Color, double)>[
                (-0.05, -0.12, orange, 0.95),
                (0.06, 0.66, blue, 0.62),
                (0.24, 0.18, blue, 0.50),
                (0.30, -0.16, orange, 0.70),
                (0.44, 0.60, orange, 0.58),
                (0.58, -0.10, blue, 0.66),
                (0.70, 0.34, orange, 0.46),
                (0.80, 0.66, blue, 0.70),
                (0.92, -0.06, orange, 0.58),
              ];
              return Stack(
                children: [
                  for (final b in blobs)
                    Positioned(
                      top: h * b.$1,
                      left: w * b.$2,
                      child: _blob(b.$3, s * b.$4),
                    ),
                ],
              );
            },
          ),
        ),
        child,
      ],
    );
  }

  // A soft "flash of light" rather than a hard disc: a radial gradient that
  // fades to fully transparent at the edge, then blurred on top — so it reads as
  // a diffuse glow with no defined circle outline.
  Widget _blob(Color color, double size) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0.0)],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      );
}
