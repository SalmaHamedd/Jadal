import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
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
    final shown = topAchievements.take(6).toList();
    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared header (icon badge + title + small "show all" link) so this
          // card matches the teams/debates cards it sits between.
          JadalSectionHeader(
            icon: Icons.military_tech_rounded,
            title: context.loc.achievements,
            accent: JadalColors.primaryOrange,
            actionLabel: context.loc.showAll,
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AchievementsScreen(userId: userId, userName: userName),
              ),
            ),
          ),
          const SizedBox(height: 14),
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
