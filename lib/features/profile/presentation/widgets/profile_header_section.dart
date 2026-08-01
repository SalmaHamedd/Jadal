import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';

/// Cover band (reusing the app's own gradient palette) + a circular avatar
/// overlapping the cover/body boundary, first-letter fallback when there's
/// no `avatarUrl` (§6.1) — shared by the self Profile screen and the
/// read-only [UserProfileScreen] for other users.
class ProfileHeaderSection extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String roleLabel;
  final String? location;
  final Duration? tenure;

  const ProfileHeaderSection({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.roleLabel,
    this.location,
    this.tenure,
  });

  static const double _coverHeight = 120;
  static const double _avatarRadius = 44;

  String get _tenureLabel {
    final t = tenure;
    if (t == null) return '';
    final years = t.inDays / 365;
    if (years >= 1) return '${years.floor()} yr in debate';
    final months = t.inDays / 30;
    if (months >= 1) return '${months.floor()} mo in debate';
    return 'New to debate';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.lightTextPrimary;
    return Column(
      children: [
        SizedBox(
          height: _coverHeight + _avatarRadius,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                child: SizedBox(
                  height: _coverHeight,
                  width: double.infinity,
                  // Reuses the shared brand gradient as the cover art itself,
                  // so a new profile screen never needs its own custom asset.
                  child: const JadalGradientBackground(
                    child: SizedBox.expand(),
                  ),
                ),
              ),
              Positioned(
                top: _coverHeight - _avatarRadius,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? JadalColors.darkBackground
                        : JadalColors.lightBackground,
                  ),
                  child: CircleAvatar(
                    radius: _avatarRadius,
                    backgroundColor: JadalColors.primaryBlue,
                    backgroundImage:
                        (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(avatarUrl!)
                        : null,
                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                        ? Text(
                            name.isNotEmpty
                                ? name.substring(0, 1).toUpperCase()
                                : '?',
                            style: AppTextStyles.displayTitle(
                              context,
                            ).copyWith(fontSize: 32, color: Colors.white),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: AppTextStyles.headline(context).copyWith(color: textColor),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            _Pill(icon: Icons.badge_rounded, label: roleLabel),
            if (location != null && location!.isNotEmpty)
              _Pill(icon: Icons.location_on_rounded, label: location!),
            if (tenure != null)
              _Pill(icon: Icons.timelapse_rounded, label: _tenureLabel),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: JadalColors.primaryOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: JadalColors.primaryOrange),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.small(context).copyWith(
              fontWeight: FontWeight.w700,
              color: JadalColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}
