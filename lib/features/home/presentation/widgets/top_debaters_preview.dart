import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:jadal_app/features/statistics/data/models/leaderboard_models.dart';
import 'package:jadal_app/features/statistics/data/repositories/leaderboard_repository.dart';
import 'package:jadal_app/features/statistics/presentation/pages/public_stats_screen.dart';
import 'package:jadal_app/features/statistics/presentation/widgets/stats_theme.dart';

/// Home screen's "top debaters" strip (V2 §4) — the first three rows of the
/// points leaderboard, with "show more" opening the full public-statistics
/// screen. Loads once like [HomeDebateBanner]; renders nothing on error so a
/// failed leaderboard call never junks up the home screen.
class TopDebatersPreview extends StatefulWidget {
  const TopDebatersPreview({super.key});

  @override
  State<TopDebatersPreview> createState() => _TopDebatersPreviewState();
}

class _TopDebatersPreviewState extends State<TopDebatersPreview> {
  bool _loading = true;
  List<LeaderboardEntry> _top = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await di.sl<LeaderboardRepository>().getLeaderboard(
      LeaderboardScope.debaters,
      LeaderboardMetric.points,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      res.fold((_) {}, (board) => _top = board.entries.take(3).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_loading && _top.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.loc.topDebaters,
                style: AppTextStyles.headline(
                  context,
                ).copyWith(color: JadalColors.primaryBlue),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PublicStatsScreen()),
                ),
                child: Text(
                  context.loc.showMore,
                  style: AppTextStyles.button(
                    context,
                  ).copyWith(color: JadalColors.primaryOrange),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  (isDark ? JadalColors.darkSurface : JadalColors.lightSurface)
                      .withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: StatsTheme.border(context)),
            ),
            child: _loading
                // Fixed-height placeholder so the non-scrolling home column
                // doesn't jump when the rows land.
                ? const SizedBox(
                    height: 132,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final entry in _top)
                        LeaderboardRow(
                          entry: entry,
                          metric: LeaderboardMetric.points,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                userId: entry.subjectId,
                                userName: entry.name,
                              ),
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
