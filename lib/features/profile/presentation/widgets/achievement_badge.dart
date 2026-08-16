import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jadal_app/core/constants/appImgaeAsset.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/profile/domain/entities/achievement.dart';
import 'package:jadal_app/features/profile/presentation/widgets/achievement_dialog.dart';

/// Rank → color, presentational only (backend just sends the enum string).
Color achievementRankColor(AchievementRank rank) {
  switch (rank) {
    case AchievementRank.gold:
      return const Color(0xFFD4AF37);
    case AchievementRank.silver:
      return const Color(0xFFA7A9AC);
    case AchievementRank.bronze:
      return const Color(0xFFB08D57);
    case AchievementRank.honorable:
      return JadalColors.primaryBlue;
    case AchievementRank.participation:
      return JadalColors.judgesGrey;
  }
}

/// Rank → localized display label.
String achievementRankLabel(BuildContext context, AchievementRank rank) {
  final loc = context.loc;
  switch (rank) {
    case AchievementRank.gold:
      return loc.achievementRankGold;
    case AchievementRank.silver:
      return loc.achievementRankSilver;
    case AchievementRank.bronze:
      return loc.achievementRankBronze;
    case AchievementRank.honorable:
      return loc.achievementRankHonorable;
    case AchievementRank.participation:
      return loc.achievementRankParticipation;
  }
}

/// A single achievement. The tier color sits FLUSH against the image
/// (no story-ring gap), the image stays in a fixed position regardless of the
/// name's line count (the name lives in a fixed two-line box below), and
/// tapping opens the [AchievementDialog].
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final double size;
  const AchievementBadge({
    super.key,
    required this.achievement,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    final color = achievementRankColor(achievement.rank);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Fixed two-line reservation so the image never shifts up or down when a
    // name takes one line instead of two.
    final nameStyle = AppTextStyles.small(context).copyWith(
      height: 1.25,
      color: isDark
          ? JadalColors.darkTextSecondary
          : JadalColors.lightTextSecondary,
    );
    final nameBoxHeight = (nameStyle.fontSize ?? 11) * 1.25 * 2 + 2;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showDialog(
        context: context,
        builder: (_) => AchievementDialog(achievement: achievement),
      ),
      child: SizedBox(
        width: size + 18,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Flush tier ring — no gap between color and image.
                border: Border.all(color: color, width: 3),
              ),
              child: ClipOval(
                child:
                    (achievement.imageUrl != null &&
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
            const SizedBox(height: 6),
            SizedBox(
              height: nameBoxHeight,
              child: Text(
                achievement.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: nameStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
