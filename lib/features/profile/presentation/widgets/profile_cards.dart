import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';

/// The profile screens' content surface. Now a thin alias over [JadalSurface]
/// so Profile, Home and every other redesigned screen share one card
/// treatment instead of each maintaining its own near-identical container.
class ProfileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const ProfileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) =>
      JadalSurface(padding: padding, child: child);
}

/// One private-details line.
/// Every row shares the same leading edge (the age row used to start further
/// left than its neighbours), and the value wraps freely instead of
/// truncating, so a long email is shown in full rather than elided. A hairline
/// separates rows so the card reads as a table rather than a loose stack.
class ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  /// A per-field accent instead of the same blue on every row.
  /// Deliberately small: only the icon plate, the icon, and a hair of tint on
  /// the value. The layout, hairlines and typography are untouched.
  final Color accent;

  const ProfileDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.accent = JadalColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    final dark = jadalIsDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : JadalColors.primaryBlue.withValues(alpha: 0.07),
                ),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: dark ? 0.18 : 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.small(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: jadalTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  softWrap: true,
                  style: AppTextStyles.bodyEmphasis(context).copyWith(
                    // A hint of the accent in light theme; dark keeps the
                    // plain primary so the value never dims.
                    color: dark
                        ? jadalTextPrimary(context)
                        : Color.lerp(
                            jadalTextPrimary(context),
                            accent,
                            0.22,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
