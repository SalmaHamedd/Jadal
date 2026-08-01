import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../data/models/team_summary_model.dart';
import '../../data/repositories/team_summary_repository.dart';
import '../widgets/stats_theme.dart';

/// V2 §3 — the coach's team analysis: four averages across the teams they
/// train (improvement / win rate / score / member activity), one tile each.
/// A deliberately simple screen — the backend ships scalars, not series.
class CoachTeamSummaryScreen extends StatefulWidget {
  final int trainerId;
  final String? trainerName;
  const CoachTeamSummaryScreen({
    super.key,
    required this.trainerId,
    this.trainerName,
  });

  @override
  State<CoachTeamSummaryScreen> createState() => _CoachTeamSummaryScreenState();
}

class _CoachTeamSummaryScreenState extends State<CoachTeamSummaryScreen> {
  final _repo = TeamSummaryRepository();
  TeamSummaryStat? _stat;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _stat = null;
      _error = null;
    });
    final res = await _repo.getTeamSummary(widget.trainerId);
    if (!mounted) return;
    res.fold(
      (f) => setState(() => _error = f.message),
      (s) => setState(() => _stat = s),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatsTheme.isDark(context)
          ? JadalColors.darkBackground
          : JadalColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.trainerName == null
              ? context.loc.statsTeamAnalysisTitle
              : context.loc.statsTeamAnalysisTitleWithName(widget.trainerName!),
          style: AppTextStyles.title(context),
        ),
      ),
      body: JadalGradientBackground(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: JadalColors.judgesGrey,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: StatsTheme.textPrimary(context)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.loc.retry,
                  style: AppTextStyles.button(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final stat = _stat;
    if (stat == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.loc.statsAveragedAcrossTeams,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: StatsTheme.textSecondary(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: JadalColors.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.loc.statsTeamsCount(stat.teamsCounted),
                  style: AppTextStyles.small(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: JadalColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.trending_up_rounded,
                  label: context.loc.statsAvgImprovement,
                  value:
                      '${stat.teamAvgImprovement >= 0 ? '+' : ''}'
                      '${stat.teamAvgImprovement.toStringAsFixed(1)}',
                  color: stat.teamAvgImprovement >= 0
                      ? JadalColors.positiveGreen
                      : JadalColors.negativeRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.percent_rounded,
                  label: context.loc.statsAvgWinRate,
                  value: '${(stat.teamAvgWinRate * 100).toStringAsFixed(0)}%',
                  color: JadalColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.speed_rounded,
                  label: context.loc.statsKindAvgScore,
                  value: stat.teamAvgScore.toStringAsFixed(1),
                  color: JadalColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.local_fire_department_rounded,
                  label: context.loc.statsAvgMemberActivity,
                  value:
                      '${stat.teamAvgActive >= 0 ? '+' : ''}'
                      '${stat.teamAvgActive.toStringAsFixed(1)}',
                  color: stat.teamAvgActive >= 0
                      ? JadalColors.positiveGreen
                      : JadalColors.negativeRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StatsCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: Text(
              value,
              style: AppTextStyles.displayTitle(context).copyWith(color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: StatsTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
