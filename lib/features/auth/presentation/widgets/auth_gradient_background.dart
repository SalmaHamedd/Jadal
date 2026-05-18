import 'package:flutter/material.dart';
import 'package:jadal_app/core/colors.dart';

class AuthGradientBackground extends StatelessWidget {
  final Widget child;

  const AuthGradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepblue,
            AppColors.warmorange,
          ],
        ),
      ),
      child: child,
    );
  }
}