import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/avatar_palette.dart';
import '../../../../core/error/failure_text.dart';
import '../../../../core/widgets/jadal_error_view.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../live_debate/presentation/widgets/debate_screen_header.dart';
import '../../data/models/activity_stat_model.dart';
import '../../data/models/debater_stats_models.dart';
import '../../data/models/team_analysis_models.dart';
import '../../data/repositories/team_analysis_repository.dart';
import '../widgets/stats_activity_view.dart';
import '../widgets/stats_bar_chart.dart';
import '../utils/stats_excel_exporter.dart';
import '../widgets/stats_improvement_view.dart';
import '../widgets/stats_theme.dart';

/// Which per-team metric is on screen.
enum _TeamMetric { winRate, avgScore, improvement, activity, combinations }

/// Upper bound for the line-up analysis' minimum-appearances stepper — i.e.
/// how many times a line-up must have played to be listed, NOT how many people
/// are in it. A coach with a long season may legitimately want to see only
/// well-established line-ups, so this stays generous; the backend accepts
/// 1..100 and returns a `below_min_debates` reason when nothing qualifies.
const int _kMaxMinDebates = 20;

/// One team's full analysis: the four metrics the debater
/// screen already knows how to render (the backend returns those envelopes
/// verbatim, so the existing views are reused), plus the new line-up analysis.
class CoachTeamDetailScreen extends StatefulWidget {
  final int teamId;
  final String teamName;

  const CoachTeamDetailScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<CoachTeamDetailScreen> createState() => _CoachTeamDetailScreenState();
}

class _CoachTeamDetailScreenState extends State<CoachTeamDetailScreen> {
  final _repo = TeamAnalysisRepository();

  _TeamMetric _metric = _TeamMetric.winRate;
  final StatsFilter _filter = const StatsFilter(groupBy: StatsGroupBy.month);
  CombinationMetric _comboMetric = CombinationMetric.winRate;
  int _minDebates = 2;

  bool _loading = true;
  String? _error;

  BucketedStat? _bucketed;
  ImprovementStat? _improvement;
  ActivityStat? _activity;
  int _membersCounted = 0;
  TeamCombinationsStat? _combinations;

  /// Drops the result of a superseded request when the coach taps quickly.
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });

    void fail(String m) {
      if (mounted && seq == _seq) {
        setState(() {
          _error = m;
          _loading = false;
        });
      }
    }

    void done(VoidCallback apply) {
      if (mounted && seq == _seq) {
        setState(() {
          apply();
          _loading = false;
        });
      }
    }

    switch (_metric) {
      case _TeamMetric.winRate:
      case _TeamMetric.avgScore:
        final metric = _metric == _TeamMetric.winRate
            ? 'win-rate'
            : 'avg-score';
        final res = await _repo.getTeamBucketed(widget.teamId, metric, _filter);
        res.fold((f) => fail(f.message), (r) => done(() => _bucketed = r));
      case _TeamMetric.improvement:
        final res = await _repo.getTeamImprovement(widget.teamId, _filter);
        res.fold((f) => fail(f.message), (r) => done(() => _improvement = r));
      case _TeamMetric.activity:
        final res = await _repo.getTeamActivity(widget.teamId, _filter);
        res.fold(
          (f) => fail(f.message),
          (r) => done(() {
            _activity = r.stat;
            _membersCounted = r.membersCounted;
          }),
        );
      case _TeamMetric.combinations:
        final res = await _repo.getTeamCombinations(
          widget.teamId,
          from: _filter.from,
          to: _filter.to,
          frameworks: _filter.frameworks,
          metric: _comboMetric,
          minDebates: _minDebates,
        );
        res.fold((f) => fail(f.message), (r) => done(() => _combinations = r));
    }
  }

  void _setMetric(_TeamMetric m) {
    if (m == _metric) return;
    setState(() => _metric = m);
    _load();
  }

  bool get _hasData => switch (_metric) {
    _TeamMetric.winRate || _TeamMetric.avgScore => _bucketed != null,
    _TeamMetric.improvement => _improvement != null,
    _TeamMetric.activity => _activity != null,
    _TeamMetric.combinations => _combinations != null,
  };

  String get _metricWire => switch (_metric) {
    _TeamMetric.winRate => 'win-rate',
    _TeamMetric.avgScore => 'avg-score',
    _TeamMetric.improvement => 'improvement',
    _TeamMetric.activity => 'activity',
    _TeamMetric.combinations => 'combinations',
  };

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    final nothingToExport = context.loc.statsNothingToExport;
    final shareText = context.loc.statsShareText;
    final shareSubject = context.loc.statsShareSubject;
    final exportFailed = context.loc.statsExportFailed;
    try {
      final bytes = StatsExcelExporter.buildTeam(
        teamName: widget.teamName,
        metric: _metricWire,
        filter: _filter,
        bucketed:
            (_metric == _TeamMetric.winRate ||
                _metric == _TeamMetric.avgScore)
            ? _bucketed
            : null,
        improvement: _metric == _TeamMetric.improvement ? _improvement : null,
        activity: _metric == _TeamMetric.activity ? _activity : null,
        membersCounted: _membersCounted,
        combinations: _metric == _TeamMetric.combinations
            ? _combinations
            : null,
      );
      if (bytes == null) {
        messenger.showSnackBar(SnackBar(content: Text(nothingToExport)));
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${StatsExcelExporter.teamFileName(_metricWire)}',
      );
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: shareSubject,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(exportFailed('$e'))));
    }
  }

  String _label(BuildContext context, _TeamMetric m) => switch (m) {
    _TeamMetric.winRate => context.loc.statsKindWinRate,
    _TeamMetric.avgScore => context.loc.statsKindAvgScore,
    _TeamMetric.improvement => context.loc.statsKindImprovement,
    _TeamMetric.activity => context.loc.statsKindActivity,
    _TeamMetric.combinations => context.loc.statsKindCombinations,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatsTheme.isDark(context)
          ? JadalColors.darkBackground
          : JadalColors.lightBackground,
      body: JadalGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              DebateScreenHeader(
                title: widget.teamName,
                actions: [
                  IconButton(
                    tooltip: context.loc.statsExportTooltip,
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: _hasData ? _export : null,
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final m in _TeamMetric.values) ...[
                            if (m != _TeamMetric.values.first)
                              const SizedBox(width: 8),
                            StatsChip(
                              label: _label(context, m),
                              selected: m == _metric,
                              accent: JadalColors.primaryBlue,
                              onTap: () => _setMetric(m),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_metric == _TeamMetric.combinations)
                      StatsCard(
                        child: _CombinationFilters(
                          metric: _comboMetric,
                          minDebates: _minDebates,
                          onMetric: (m) {
                            setState(() => _comboMetric = m);
                            _load();
                          },
                          onMinDebates: (v) {
                            setState(() => _minDebates = v);
                            _load();
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    _body(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return StatsCard(
        child: JadalErrorView(
          compact: true,
          icon: Icons.lock_outline_rounded,
          message: FailureText.fromMessage(context, _error),
          onRetry: _load,
        ),
      );
    }

    switch (_metric) {
      case _TeamMetric.winRate:
      case _TeamMetric.avgScore:
        final data = _bucketed;
        if (data == null || data.isEmpty) return _empty(context);
        return StatsCard(
          child: StatsBarChart(
            data: data,
            kind: _metric == _TeamMetric.winRate
                ? StatKind.winRate
                : StatKind.avgScore,
          ),
        );
      case _TeamMetric.improvement:
        final data = _improvement;
        if (data == null) return _empty(context);
        return StatsCard(child: StatsImprovementView(data: data));
      case _TeamMetric.activity:
        final data = _activity;
        if (data == null) return _empty(context);
        return StatsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The backend is explicit that team activity is a SUM over the
              // team's current members, so it scales with squad size. Showing
              // the per-member average alongside stops the raw number inviting
              // invalid cross-team comparisons.
              if (_membersCounted > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    context.loc.statsPerMemberAverage(
                      (data.totalValue / _membersCounted).toStringAsFixed(1),
                    ),
                    style: AppTextStyles.small(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: StatsTheme.textSecondary(context),
                    ),
                  ),
                ),
              StatsActivityView(data: data),
            ],
          ),
        );
      case _TeamMetric.combinations:
        final data = _combinations;
        if (data == null) return _empty(context);
        return _CombinationsView(data: data, metric: _comboMetric);
    }
  }

  Widget _empty(BuildContext context) => StatsCard(
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

class _CombinationFilters extends StatelessWidget {
  final CombinationMetric metric;
  final int minDebates;
  final ValueChanged<CombinationMetric> onMetric;
  final ValueChanged<int> onMinDebates;

  const _CombinationFilters({
    required this.metric,
    required this.minDebates,
    required this.onMetric,
    required this.onMinDebates,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatsChip(
              label: loc.statsKindWinRate,
              selected: metric == CombinationMetric.winRate,
              accent: JadalColors.primaryOrange,
              onTap: () => onMetric(CombinationMetric.winRate),
            ),
            const SizedBox(width: 8),
            StatsChip(
              label: loc.statsKindAvgScore,
              selected: metric == CombinationMetric.avgScore,
              accent: JadalColors.primaryOrange,
              onTap: () => onMetric(CombinationMetric.avgScore),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                loc.statsMinDebates,
                style: AppTextStyles.small(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: StatsTheme.textSecondary(context),
                ),
              ),
            ),
            IconButton(
              onPressed: minDebates > 1
                  ? () => onMinDebates(minDebates - 1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Text(
              '$minDebates',
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w800,
                color: StatsTheme.textPrimary(context),
              ),
            ),
            IconButton(
              onPressed: minDebates < _kMaxMinDebates
                  ? () => onMinDebates(minDebates + 1)
                  : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

/// The ranked line-ups.
class _CombinationsView extends StatelessWidget {
  final TeamCombinationsStat data;
  final CombinationMetric metric;

  const _CombinationsView({required this.data, required this.metric});

  String _format(double? v) {
    if (v == null) return '—';
    return metric == CombinationMetric.winRate
        ? '${(v * 100).toStringAsFixed(0)}%'
        : v.toStringAsFixed(1);
  }

  String _emptyMessage(BuildContext context) => switch (data.reason) {
    'no_scored_line_ups' => context.loc.statsCombinationsEmptyNoScores,
    'below_min_debates' => context.loc.statsCombinationsEmptyBelowMin(
      data.minDebates,
    ),
    _ => context.loc.statsCombinationsEmptyNoDebates,
  };

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    if (data.combinations.isEmpty) {
      return StatsCard(
        child: Column(
          children: [
            const Icon(
              Icons.groups_2_outlined,
              size: 44,
              color: JadalColors.judgesGrey,
            ),
            const SizedBox(height: 10),
            Text(
              _emptyMessage(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: StatsTheme.textSecondary(context)),
            ),
          ],
        ),
      );
    }

    final baseline = data.baseline.valueFor(metric);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The baseline is what makes a line-up's number readable — "+29% above
        // the team average" rather than a bare 83%.
        if (baseline != null)
          StatsCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              loc.statsTeamBaseline(
                _format(baseline),
                data.baseline.nDebates,
              ),
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w700,
                color: StatsTheme.textSecondary(context),
              ),
            ),
          ),
        if (data.isTruncated) ...[
          const SizedBox(height: 8),
          Text(
            loc.statsShowingLineups(
              data.combinations.length,
              data.distinctCombinations,
            ),
            style: AppTextStyles.small(context).copyWith(
              fontStyle: FontStyle.italic,
              color: StatsTheme.textSecondary(context),
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (final c in data.combinations) ...[
          _CombinationCard(
            combination: c,
            metric: metric,
            baseline: baseline,
            minDebates: data.minDebates,
            format: _format,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CombinationCard extends StatelessWidget {
  final TeamCombination combination;
  final CombinationMetric metric;
  final double? baseline;
  final int minDebates;
  final String Function(double?) format;

  const _CombinationCard({
    required this.combination,
    required this.metric,
    required this.baseline,
    required this.minDebates,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final value = combination.valueFor(metric);
    final delta = (value != null && baseline != null) ? value - baseline! : null;
    final belowSample = combination.nDebates < minDebates;

    return StatsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in combination.members)
                      _MemberChip(member: m),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    format(value),
                    style: AppTextStyles.title(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: StatsTheme.textPrimary(context),
                    ),
                  ),
                  if (delta != null)
                    Text(
                      // Arrow + sign, so the comparison survives
                      // colour-vision deficiency and greyscale.
                      metric == CombinationMetric.winRate
                          ? signedWithArrow(delta * 100, decimals: 0)
                          : signedWithArrow(delta),
                      style: AppTextStyles.small(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: delta >= 0
                            ? JadalColors.positiveGreen
                            : JadalColors.negativeRed,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color:
                      (belowSample
                              ? JadalColors.judgesGrey
                              : JadalColors.primaryBlue)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.statsLineupDebates(combination.nDebates),
                  style: AppTextStyles.small(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: belowSample
                        ? JadalColors.judgesGrey
                        : JadalColors.primaryBlue,
                  ),
                ),
              ),
              const Spacer(),
              if (baseline != null)
                Text(
                  loc.statsVsTeamAverage,
                  style: AppTextStyles.small(
                    context,
                  ).copyWith(color: StatsTheme.textSecondary(context)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final CombinationMember member;
  const _MemberChip({required this.member});

  @override
  Widget build(BuildContext context) {
    // A departed member is greyed and labelled, so a historical line-up stays
    // honest instead of implying the squad still looks like that.
    final gone = !member.isCurrentMember;
    final bg = gone
        ? JadalColors.judgesGrey
        : userAvatarColor(member.userId);
    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: 3,
        end: 9,
        top: 3,
        bottom: 3,
      ),
      decoration: BoxDecoration(
        color: StatsTheme.isDark(context)
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: bg,
            child: Text(
              member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
              style: AppTextStyles.small(context).copyWith(
                fontWeight: FontWeight.w800,
                color: gone ? Colors.white : userAvatarForeground(bg),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            member.name,
            style: AppTextStyles.small(context).copyWith(
              fontWeight: FontWeight.w700,
              color: gone
                  ? StatsTheme.textSecondary(context)
                  : StatsTheme.textPrimary(context),
            ),
          ),
          if (gone) ...[
            const SizedBox(width: 4),
            Text(
              '· ${context.loc.statsLineupLeft}',
              style: AppTextStyles.small(
                context,
              ).copyWith(color: StatsTheme.textSecondary(context)),
            ),
          ],
        ],
      ),
    );
  }
}
