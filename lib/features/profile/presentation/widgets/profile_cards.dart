import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';

/// §6.2 — the profile screens' shared surface: the app's standard floating
/// card (mirrors the statistics screens' StatsCard) so both profile screens
/// use exactly the same containers instead of painting text on the gradient.
class ProfileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const ProfileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            (dark ? JadalColors.darkSurfaceElevated : JadalColors.lightSurface)
                .withValues(alpha: dark ? 0.85 : 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.07)
              : JadalColors.primaryBlue.withValues(alpha: 0.08),
        ),
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

/// §6.7 — one private-details line. Every row shares the same leading edge
/// (icon → label → value in a single left-aligned column flow), and the value
/// wraps freely instead of truncating — the full email is always visible.
class ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const ProfileDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: JadalColors.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: JadalColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.small(
                    context,
                  ).copyWith(color: JadalColors.judgesGrey),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  softWrap: true,
                  style: AppTextStyles.bodyEmphasis(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
