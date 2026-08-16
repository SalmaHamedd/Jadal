import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jadal_app/core/constants/appImgaeAsset.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_dialog.dart';
import 'package:jadal_app/features/profile/domain/entities/achievement.dart';
import 'package:jadal_app/features/profile/presentation/widgets/achievement_badge.dart';

/// Tapping an achievement opens this dialog: the image with its flush
/// tier ring, the rank written out clearly, and the FULL name scrollable in
/// the body (same Expanded → Center → SingleChildScrollView pattern as the
/// live debate's motion dialog).
class AchievementDialog extends StatelessWidget {
  final Achievement achievement;
  const AchievementDialog({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = achievementRankColor(achievement.rank);
    final rankLabel = achievementRankLabel(context, achievement.rank);
    return JadalDialog(
      width: size.width * 0.86,
      height: size.height * 0.5,
      firstColor: color,
      secondColor: color,
      bodyColor: dark ? JadalColors.darkSurfaceElevated : JadalColors.lightSurface,
      icon: Icons.emoji_events_rounded,
      title: context.loc.achievements,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3.5),
              ),
              child: ClipOval(
                child: (achievement.imageUrl != null &&
                        achievement.imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: achievement.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Image.asset(
                          AppImageAsset.achievementPlaceholder,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        AppImageAsset.achievementPlaceholder,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rankLabel,
                style: AppTextStyles.bodyEmphasis(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    achievement.name,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle(context).copyWith(
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: dark
                          ? JadalColors.darkTextPrimary
                          : JadalColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
