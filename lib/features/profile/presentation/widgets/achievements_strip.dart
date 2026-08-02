import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/profile/domain/entities/achievement.dart';
import 'package:jadal_app/features/profile/presentation/screens/achievements_screen.dart';
import 'package:jadal_app/features/profile/presentation/widgets/achievement_badge.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_cards.dart';

/// §6.8 — the profile's achievements block: at most 6 achievements laid out
/// as 2 rows of 3 inside the shared profile card, with a SMALL "show all"
/// affordance (small font + small arrow) opening the full page. Renders
/// nothing if there are no achievements at all.
class AchievementsStrip extends StatelessWidget {
  final int userId;
  final String userName;
  final List<Achievement> topAchievements;
  const AchievementsStrip({
    super.key,
    required this.userId,
    required this.userName,
    required this.topAchievements,
  });

  @override
  Widget build(BuildContext context) {
    if (topAchievements.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shown = topAchievements.take(6).toList();
    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.loc.achievements,
                style: AppTextStyles.subtitle(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? JadalColors.darkTextPrimary
                      : JadalColors.lightTextPrimary,
                ),
              ),
              // Small text + small arrow — deliberately NOT a big bar.
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AchievementsScreen(userId: userId, userName: userName),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.loc.showAll,
                        style: AppTextStyles.small(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: JadalColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 15,
                        color: JadalColors.primaryOrange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.80,
            ),
            itemCount: shown.length,
            itemBuilder: (context, i) => Center(
              child: AchievementBadge(achievement: shown[i], size: 76),
            ),
          ),
        ],
      ),
    );
  }
}
