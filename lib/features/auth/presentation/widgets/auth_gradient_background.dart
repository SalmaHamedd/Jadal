import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthGradientBackground extends StatelessWidget {
  final Widget child;

  const AuthGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? JadalColors.darkBackground : JadalColors.lightBackground,
      child: child,
    );
  }
}

class AuthHeroGradient extends StatelessWidget {
  final Widget child;
  final double height;

  const AuthHeroGradient({super.key, required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JadalColors.primaryBlue.withValues(alpha: 0.92),
            JadalColors.primaryOrange.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: child,
    );
  }
}

class AuthGradientDivider extends StatelessWidget {
  const AuthGradientDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            JadalColors.primaryBlue,
            JadalColors.primaryOrange,
          ],
        ),
      ),
    );
  }
}
