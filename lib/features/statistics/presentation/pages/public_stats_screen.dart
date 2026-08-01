import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../di/injection_container.dart' as di;
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../data/models/leaderboard_models.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../cubits/leaderboard_cubit.dart';
import '../widgets/stats_theme.dart';

/// V2 §3/§4 — the public statistics screen behind the home screen's
/// "show more": top-10 leaderboards for debaters and teams across every
/// metric. Fixed-height shell (no page scroll): scope + metric selectors up
/// top, one board filling the rest of the viewport.
class PublicStatsScreen extends StatelessWidget {
  const PublicStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LeaderboardCubit(repo: di.sl<LeaderboardRepository>())..load(),
      child: Scaffold(
        backgroundColor: StatsTheme.isDark(context)
            ? JadalColors.darkBackground
            : JadalColors.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            context.loc.statsTopOfJadal,
            style: AppTextStyles.title(context),
          ),
        ),
        body: const JadalGradientBackground(child: _Body()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        final cubit = context.read<LeaderboardCubit>();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ScopeSwitch(active: state.scope, onChanged: cubit.setScope),
              const SizedBox(height: 12),
              _MetricChips(state: state, onChanged: cubit.setMetric),
              const SizedBox(height: 14),
              Expanded(child: _Board(state: state)),
            ],
          ),
        );
      },
    );
  }
}

class _ScopeSwitch extends StatelessWidget {
  final LeaderboardScope active;
  final ValueChanged<LeaderboardScope> onChanged;
  const _ScopeSwitch({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dark = StatsTheme.isDark(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final scope in LeaderboardScope.values)
            Expanded(
              child: _ScopeButton(
                label: scope == LeaderboardScope.debaters
                    ? context.loc.statsScopeDebaters
                    : context.loc.statsScopeTeams,
                icon: scope == LeaderboardScope.debaters
                    ? Icons.person_rounded
                    : Icons.groups_rounded,
                selected: scope == active,
                onTap: () => onChanged(scope),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScopeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ScopeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [JadalColors.primaryBlue, JadalColors.primaryOrange],
                ),
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? Colors.white
                    : StatsTheme.textSecondary(context),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : StatsTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChips extends StatelessWidget {
  final LeaderboardState state;
  final ValueChanged<LeaderboardMetric> onChanged;
  const _MetricChips({required this.state, required this.onChanged});

  static String _label(BuildContext context, LeaderboardMetric m) =>
      switch (m) {
        LeaderboardMetric.points => context.loc.statsMetricPoints,
        LeaderboardMetric.winRate => context.loc.statsKindWinRate,
        LeaderboardMetric.avgScore => context.loc.statsKindAvgScore,
        LeaderboardMetric.bestSpeaker => context.loc.statsKindBestSpeaker,
        LeaderboardMetric.improvement => context.loc.statsKindImprovement,
      };

  @override
  Widget build(BuildContext context) {
    final metrics = LeaderboardMetric.forScope(state.scope);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final metric = metrics[i];
          return StatsChip(
            label: _label(context, metric),
            selected: metric == state.metric,
            onTap: () => onChanged(metric),
          );
        },
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final LeaderboardState state;
  const _Board({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == LeaderboardStatus.error) {
      return StatsCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: JadalColors.judgesGrey,
            ),
            const SizedBox(height: 10),
            Text(
              state.error ?? context.loc.statsSomethingWrong,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: StatsTheme.textPrimary(context)),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: context.read<LeaderboardCubit>().load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                context.loc.retry,
                style: AppTextStyles.button(context),
              ),
            ),
          ],
        ),
      );
    }
    final board = state.board;
    if (state.status == LeaderboardStatus.loading || board == null) {
      return const StatsCard(child: Center(child: CircularProgressIndicator()));
    }
    if (board.entries.isEmpty) {
      return StatsCard(
        child: Center(
          child: Text(
            context.loc.statsNoEntriesYet,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: StatsTheme.textSecondary(context)),
          ),
        ),
      );
    }
    return StatsCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // AnimatedSwitcher keyed per (scope, metric) so board flips cross-fade.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: ListView.separated(
          key: ValueKey('${board.scope}-${board.metric}'),
          padding: EdgeInsets.zero,
          itemCount: board.entries.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: StatsTheme.border(context)),
          itemBuilder: (context, i) {
            final entry = board.entries[i];
            return LeaderboardRow(
              entry: entry,
              metric: board.metric,
              // Debaters link to their public profile; there's no team-detail
              // screen in the app yet, so team rows stay non-tappable.
              onTap: board.scope == LeaderboardScope.debaters
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(
                          userId: entry.subjectId,
                          userName: entry.name,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

/// One ranked row — shared with the home screen's top-3 preview so the two
/// surfaces can't drift apart visually.
class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final LeaderboardMetric metric;
  final VoidCallback? onTap;
  const LeaderboardRow({
    super.key,
    required this.entry,
    required this.metric,
    this.onTap,
  });

  static const _gold = Color(0xFFD4A017);
  static const _silver = Color(0xFF9AA0A6);
  static const _bronze = Color(0xFFCD7F32);

  static Color? medalColor(int rank) => switch (rank) {
    1 => _gold,
    2 => _silver,
    3 => _bronze,
    _ => null,
  };

  static String formatValue(LeaderboardMetric metric, num value) =>
      switch (metric) {
        LeaderboardMetric.points => '${value.round()}',
        LeaderboardMetric.winRate => '${(value * 100).toStringAsFixed(0)}%',
        LeaderboardMetric.avgScore => value.toStringAsFixed(1),
        LeaderboardMetric.bestSpeaker => '${value.round()}×',
        LeaderboardMetric.improvement =>
          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}',
      };

  @override
  Widget build(BuildContext context) {
    final medal = medalColor(entry.rank);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: medal != null
                  ? Icon(Icons.emoji_events_rounded, color: medal, size: 22)
                  : Text(
                      '${entry.rank}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: StatsTheme.textSecondary(context),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: JadalColors.primaryBlue.withValues(alpha: 0.85),
              backgroundImage:
                  (entry.imageUrl != null && entry.imageUrl!.isNotEmpty)
                  ? NetworkImage(entry.imageUrl!)
                  : null,
              child: (entry.imageUrl == null || entry.imageUrl!.isEmpty)
                  ? Text(
                      entry.name.isEmpty
                          ? '?'
                          : entry.name.characters.first.toUpperCase(),
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyEmphasis(
                  context,
                ).copyWith(color: StatsTheme.textPrimary(context)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (medal ?? JadalColors.primaryOrange).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                formatValue(metric, entry.value),
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: medal ?? JadalColors.primaryOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
