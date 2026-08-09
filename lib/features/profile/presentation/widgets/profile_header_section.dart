import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jadal_app/core/constants/appImgaeAsset.dart';
import 'package:jadal_app/core/function/media_url.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/avatar_palette.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';

/// The ONE profile header, shared verbatim by the self Profile screen and the
/// read-only public profile.
///
/// The cover is **full-bleed**: it starts at the very top of the screen (the
/// app bar floats over it, so it runs behind the status bar) with no side
/// padding, and its bottom edge is clipped into a dome. That single curved
/// mass is the screen's signature shape — it anchors the header instead of
/// letting a rectangular strip float among the cards below.
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

  /// Cover height measured from the very top of the window; the app bar and
  /// status bar sit inside it, leaving roughly 110dp of artwork visible below
  /// the bar on a typical phone.
  static const double coverHeight = 210;
  static const double _avatarRadius = 52;
  static const double _domeDepth = 44;

  /// The dome's lowest point. For the quadratic in [JadalDomeClipper] the
  /// curve at t=0.5 evaluates to exactly [coverHeight] (the +depth control
  /// point and the −depth endpoints cancel), so the avatar is centred there
  /// to straddle the curve rather than float above or below it.
  static const double _avatarTop = coverHeight - _avatarRadius - 4;

  String _tenureLabel(BuildContext context) {
    final t = tenure;
    if (t == null) return '';
    final years = t.inDays ~/ 365;
    if (years >= 1) return context.loc.tenureYears(years);
    final months = t.inDays ~/ 30;
    if (months >= 1) return context.loc.tenureMonths(months);
    return context.loc.tenureNew;
  }

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(avatarUrl);
    final bg = jadalIsDark(context)
        ? JadalColors.darkBackground
        : JadalColors.lightBackground;

    return Column(
      children: [
        SizedBox(
          // Room for the dome plus the full avatar hanging below it.
          height: coverHeight + _avatarRadius + 8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              ClipPath(
                clipper: const JadalDomeClipper(depth: _domeDepth),
                child: SizedBox(
                  height: coverHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        AppImageAsset.userCoverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: JadalColors.deepBlue),
                      ),
                      // Darkened toward the base so the white app-bar icons
                      // and the avatar ring stay legible over any artwork.
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x40000000),
                              Color(0x00000000),
                              Color(0x59000000),
                            ],
                            stops: [0, 0.45, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Avatar straddling the dome's lowest point.
              Positioned(
                top: _avatarTop,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 18,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      ),
                    ],
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
                            style: AppTextStyles.displayTitle(context)
                                .copyWith(fontSize: 38, color: Colors.white),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.displayTitle(context)
                .copyWith(color: jadalTextPrimary(context)),
          ),
        ),
        const SizedBox(height: 12),
        // Wide chips: each stretches across a share of the row instead of
        // hugging its label, so the identity block reads as a deliberate
        // stat bar rather than scattered pills.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _WideChip(
                  icon: Icons.badge_rounded,
                  label: roleLabel,
                  color: JadalColors.primaryBlue,
                ),
              ),
              if (points != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _WideChip(
                    icon: Icons.star_rounded,
                    label: '$points',
                    caption: context.loc.pointsLabel,
                    color: JadalColors.primaryOrange,
                  ),
                ),
              ],
              if (tenure != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _WideChip(
                    icon: Icons.timelapse_rounded,
                    label: _tenureLabel(context),
                    color: JadalColors.positiveGreen,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (location != null && location!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 14, color: jadalTextSecondary(context)),
              const SizedBox(width: 4),
              Text(
                location!,
                style: AppTextStyles.small(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: jadalTextSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A full-width tonal chip: icon, then the value, with an optional caption
/// underneath. Sized by its column, never by its text.
class _WideChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? caption;
  final Color color;
  const _WideChip({
    required this.icon,
    required this.label,
    this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = jadalIsDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.20 : 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w800, color: color),
          ),
          if (caption != null)
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small(context).copyWith(
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.75),
              ),
            ),
        ],
      ),
    );
  }
}
