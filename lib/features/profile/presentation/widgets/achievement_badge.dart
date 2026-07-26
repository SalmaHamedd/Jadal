import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jadal_app/core/constants/appImgaeAsset.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/profile/domain/entities/achievement.dart';

/// Rank → color, presentational only (backend just sends the enum string).
Color achievementRankColor(AchievementRank rank) {
  switch (rank) {
    case AchievementRank.gold:
      return const Color(0xFFD4AF37);
    case AchievementRank.silver:
      return const Color(0xFFA7A9AC);
    case AchievementRank.bronze:
      return const Color(0xFFB08D57);
    case AchievementRank.honoring:
      return JadalColors.primaryBlue;
    case AchievementRank.participation:
      return JadalColors.judgesGrey;
  }
}

/// A single achievement — rank-tinted ring around the image (or the shared
/// fallback asset when `imageUrl` is null), name below, clipped to a fixed
/// width so a row of these stays visually balanced regardless of name length.
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final double size;
  const AchievementBadge({super.key, required this.achievement, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final color = achievementRankColor(achievement.rank);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size + 16,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
            ),
            child: ClipOval(
              child: (achievement.imageUrl != null && achievement.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: achievement.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          Image.asset(AppImageAsset.achievementPlaceholder, fit: BoxFit.cover),
                    )
                  : Image.asset(AppImageAsset.achievementPlaceholder, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? JadalColors.darkTextSecondary : JadalColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
