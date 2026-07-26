import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/profile/domain/entities/achievement.dart';
import 'package:jadal_app/features/profile/presentation/screens/achievements_screen.dart';
import 'package:jadal_app/features/profile/presentation/widgets/achievement_badge.dart';

/// Top achievements (already highest-rank-first, most-recent per backend) +
/// a "Show all" button opening the full paginated list (§6.3). Renders
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Achievements',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                )),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AchievementsScreen(userId: userId, userName: userName),
                ),
              ),
              child: const Text('Show all', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final a in topAchievements)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AchievementBadge(achievement: a),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
