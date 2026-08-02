import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jadal_app/core/constants/appImgaeAsset.dart';
import 'package:jadal_app/core/function/media_url.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/avatar_palette.dart';

/// §6.1/§6.3 — the ONE profile header, shared verbatim by the self Profile
/// screen and the read-only [UserProfileScreen]: the fixed
/// `Jadal_user_cover_image` asset as the cover band (behind the avatar — or
/// behind the initial-letter fallback), the circular avatar overlapping the
/// cover/body boundary, then name + role/points pills.
class ProfileHeaderSection extends StatelessWidget {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String roleLabel;
  final int? points;
  final String? location;
  final Duration? tenure;

  const ProfileHeaderSection({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.roleLabel,
    this.points,
    this.location,
    this.tenure,
  });

  static const double _coverHeight = 132;
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
    final url = resolveMediaUrl(avatarUrl);
    return Column(
      children: [
        SizedBox(
          height: _coverHeight + _avatarRadius,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: _coverHeight,
                  width: double.infinity,
                  // §6.3 — the dedicated cover asset, shown behind the avatar
                  // (image or initial fallback alike) on BOTH profile screens.
                  child: Image.asset(
                    AppImageAsset.userCoverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: JadalColors.deepBlue,
                    ),
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
                    // §2.2 — deterministic per-user color for the initial.
                    backgroundColor: userAvatarColor(userId),
                    backgroundImage:
                        url != null ? CachedNetworkImageProvider(url) : null,
                    child: url == null
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
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _Pill(icon: Icons.badge_rounded, label: roleLabel),
            if (points != null)
              _Pill(icon: Icons.star_rounded, label: '$points pts'),
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
