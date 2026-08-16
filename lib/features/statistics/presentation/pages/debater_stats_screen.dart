import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/error/failure_text.dart';
import '../../../../core/widgets/jadal_error_view.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../core/widgets/jadal_segmented_switch.dart';
import '../../../../di/injection_container.dart' as di;
import '../../../live_debate/data/repositories/live_debate_repository.dart';
import '../../../live_debate/presentation/widgets/debate_screen_header.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/models/debater_stats_models.dart';
import '../../data/repositories/debater_stats_repository.dart';
import '../cubits/debater_stats_cubit.dart';
import '../utils/stats_excel_exporter.dart';
import '../widgets/stats_activity_view.dart';
import '../widgets/stats_bar_chart.dart';
import '../widgets/stats_filter_bar.dart';
import '../widgets/stats_improvement_view.dart';
import '../widgets/stats_judge_rating_view.dart';
import '../widgets/stats_ranking_list.dart';
import '../widgets/stats_theme.dart';

/// The statistics screen. Pass a [debaterId] to view a specific user; omit it
/// to resolve the signed-in user from their profile.
/// [subjectRole] gates the content: debaters get all six stats;
/// judges/trainers get an activity-only view (the debater-only metrics never
/// render for them, and the backend 422s them anyway).
class DebaterStatsScreen extends StatefulWidget {
  final int? debaterId;
  final String? debaterName;
  final String subjectRole;
  const DebaterStatsScreen({
    super.key,
    this.debaterId,
    this.debaterName,
    this.subjectRole = 'debater',
  });

  @override
  State<DebaterStatsScreen> createState() => _DebaterStatsScreenState();
}

class _DebaterStatsScreenState extends State<DebaterStatsScreen> {
  int? _id;
  String? _name;
  String? _role;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.debaterId != null) {
      _id = widget.debaterId;
      _name = widget.debaterName;
      _role = widget.subjectRole;
    } else {
      _resolveSelf();
    }
  }

  Future<void> _resolveSelf() async {
    final res = await di.sl<ProfileRepository>().getProfile();
    if (!mounted) return;
    res.fold(
      (f) => setState(() => _error = f.message),
      (p) => setState(() {
        _id = p.id;
        _name = p.name;
        _role = p.role;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Until the debater id resolves we show a plain scaffold; once ready the
    // BlocProvider wraps the whole Scaffold so the app-bar export action can read
    // the cubit's current state + filters.
    if (_id == null) {
      return Scaffold(
        backgroundColor: StatsTheme.isDark(context)
            ? JadalColors.darkBackground
            : JadalColors.lightBackground,
        // In-body header over the edge-to-edge gradient (matches
        // the debate details screen), instead of an AppBar seam.
        body: JadalGradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                DebateScreenHeader(title: context.loc.statsTitle),
                Expanded(child: _resolving(context)),
              ],
            ),
          ),
        ),
      );
    }
    final role = _role ?? 'debater';
    return BlocProvider(
      create: (_) => DebaterStatsCubit(
        repo: di.sl<DebaterStatsRepository>(),
        debaterId: _id!,
        subjectRole: role,
        frameworksLoader: di.sl<LiveDebateRepository>().getMotionFrameworks,
      )..load(),
      child: _StatsScaffold(debaterName: _name, subjectRole: role),
    );
  }

  Widget _resolving(BuildContext context) {
    if (_error != null) {
      return JadalErrorView(
        message: FailureText.fromMessage(context, _error),
        onRetry: () => setState(() {
          _error = null;
          _resolveSelf();
        }),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

/// The ready-state scaffold (inside the BlocProvider). Holds the app bar with
/// the "export to Excel sheet" action and the scrollable stats body.
class _StatsScaffold extends StatelessWidget {
  final String? debaterName;
  final String subjectRole;
  const _StatsScaffold({required this.debaterName, required this.subjectRole});

  bool _hasData(DebaterStatsState s) => switch (s.kind) {
    StatKind.ranking => s.ranking != null,
    StatKind.improvement => s.improvement != null,
    StatKind.activity => s.activity != null,
    StatKind.judgeRating => s.judgeRating != null,
    _ => s.bucketed != null,
  };

  Future<void> _export(BuildContext context, DebaterStatsState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final nothingToExport = context.loc.statsNothingToExport;
    final shareText = context.loc.statsShareText;
    final shareSubject = context.loc.statsShareSubject;
    final exportFailed = context.loc.statsExportFailed;
    try {
      final bytes = StatsExcelExporter.build(
        kind: state.kind,
        filter: state.filter,
        debaterName: debaterName ?? 'Debater',
        rankingMode: state.rankingMode,
        bucketed: state.bucketed,
        ranking: state.ranking,
        improvement: state.improvement,
        activity: state.activity,
        judgeRating: state.judgeRating,
      );
      if (bytes == null) {
        messenger.showSnackBar(SnackBar(content: Text(nothingToExport)));
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${StatsExcelExporter.fileName(state.kind)}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatsTheme.isDark(context)
          ? JadalColors.darkBackground
          : JadalColors.lightBackground,
      // In-body header over the edge-to-edge gradient (matches
      // the debate details screen), instead of an AppBar seam.
      body: JadalGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              DebateScreenHeader(
                title: debaterName == null
                    ? context.loc.statsTitle
                    : context.loc.statsTitleWithName(debaterName!),
                actions: [
                  BlocBuilder<DebaterStatsCubit, DebaterStatsState>(
                    builder: (context, state) {
                      final canExport = _hasData(state);
                      return IconButton(
                        tooltip: context.loc.statsExportTooltip,
                        icon: const Icon(Icons.ios_share_rounded),
                        onPressed: canExport
                            ? () => _export(context, state)
                            : null,
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: _StatsView(
                  debaterOnly: subjectRole == 'debater',
                  isJudge: subjectRole == 'judge',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  final bool debaterOnly;
  final bool isJudge;
  const _StatsView({required this.debaterOnly, required this.isJudge});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebaterStatsCubit, DebaterStatsState>(
      builder: (context, state) {
        return RefreshIndicator(
          color: JadalColors.primaryOrange,
          onRefresh: () async => context.read<DebaterStatsCubit>().load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              // Judges/trainers only ever see activity, so there are no
              // stat tabs for them. — but the stat still has to name
              // itself, or the screen presents an unlabelled number.
              if (debaterOnly)
                _KindSelector(active: state.kind)
              else if (isJudge)
                // Judges have two stats now, so the header card
                // becomes a real selector.
                JadalSegmentedSwitch<StatKind>(
                  values: const [StatKind.activity, StatKind.judgeRating],
                  active: state.kind,
                  onChanged: context.read<DebaterStatsCubit>().setKind,
                  labelOf: (k) => k == StatKind.activity
                      ? context.loc.statsKindActivity
                      : context.loc.statsKindRating,
                  iconOf: (k) => k == StatKind.activity
                      ? Icons.local_fire_department_rounded
                      : Icons.star_rounded,
                )
              else
                const _StatHeaderCard(),
              const SizedBox(height: 16),
              // Activity takes from/to/group_by (and nothing else),
              // so it gets a reduced bar rather than none at all. Hiding the bar
              // outright is what made the trend chart unreachable.
              StatsCard(
                child: StatsFilterBar(
                  state: state,
                  // Judge ratings have no position dimension, and the framework
                  // options are only fetched for debater subjects — so it takes
                  // the same reduced period/grouping bar as activity.
                  periodOnly:
                      state.kind == StatKind.activity ||
                      state.kind == StatKind.judgeRating,
                ),
              ),
              const SizedBox(height: 16),
              _Content(state: state),
            ],
          ),
        );
      },
    );
  }
}

/// Judges and trainers see exactly one stat, so the tab strip is
/// hidden for them; without this card the screen showed a big number with
/// nothing naming it. Names the stat and says what it actually measures.
class _StatHeaderCard extends StatelessWidget {
  const _StatHeaderCard();

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return StatsCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: JadalColors.primaryOrange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 21,
              color: JadalColors.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.statsKindActivity,
                  style: AppTextStyles.subtitle(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: StatsTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.statsActivitySubtitle,
                  style: AppTextStyles.small(
                    context,
                  ).copyWith(color: StatsTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The five stat tabs as a horizontally-scrollable segmented selector.
class _KindSelector extends StatelessWidget {
  final StatKind active;
  const _KindSelector({required this.active});

  List<({StatKind kind, String label, IconData icon})> _items(
    BuildContext context,
  ) => [
    (
      kind: StatKind.winRate,
      label: context.loc.statsKindWinRate,
      icon: Icons.percent_rounded,
    ),
    (
      kind: StatKind.avgScore,
      label: context.loc.statsKindAvgScore,
      icon: Icons.speed_rounded,
    ),
    (
      kind: StatKind.bestSpeaker,
      label: context.loc.statsKindBestSpeaker,
      icon: Icons.workspace_premium_rounded,
    ),
    (
      kind: StatKind.ranking,
      label: context.loc.statsKindRanking,
      icon: Icons.format_list_numbered_rounded,
    ),
    (
      kind: StatKind.improvement,
      label: context.loc.statsKindImprovement,
      icon: Icons.trending_up_rounded,
    ),
    (
      kind: StatKind.activity,
      label: context.loc.statsKindActivity,
      icon: Icons.local_fire_department_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebaterStatsCubit>();
    final items = _items(context);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final selected = item.kind == active;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            child: Material(
              color: selected
                  ? null
                  : (StatsTheme.isDark(context)
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(30),
              child: Ink(
                decoration: selected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            JadalColors.primaryBlue,
                            JadalColors.primaryOrange,
                          ],
                        ),
                      )
                    : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => cubit.setKind(item.kind),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 17,
                          color: selected
                              ? Colors.white
                              : StatsTheme.textSecondary(context),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          item.label,
                          style: AppTextStyles.body(context).copyWith(
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : StatsTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final DebaterStatsState state;
  const _Content({required this.state});

  bool get _hasData => switch (state.kind) {
    StatKind.ranking => state.ranking != null,
    StatKind.improvement => state.improvement != null,
    StatKind.activity => state.activity != null,
    StatKind.judgeRating => state.judgeRating != null,
    _ => state.bucketed != null,
  };

  @override
  Widget build(BuildContext context) {
    // Nothing for this stat yet → full loader / first-load error.
    if (!_hasData) {
      if (state.status == StatsStatus.error) {
        return _ErrorCard(
          message: state.error ?? context.loc.statsSomethingWrong,
          state: state,
        );
      }
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // A thin top strip keeps the prior chart visible (so it can morph) while
        // the next payload loads.
        AnimatedOpacity(
          opacity: state.status == StatsStatus.loading ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const _ThinProgress(),
        ),
        // A non-blocking error banner over stale data (e.g. an invalid filter).
        if (state.status == StatsStatus.error)
          _ErrorBanner(
            message: state.error ?? context.loc.statsCouldNotUpdateFilters,
          ),
        // View-family switch: bucketed charts share one key so they MORPH between
        // win-rate/avg-score/best-speaker; ranking & improvement cross-fade.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _viewForFamily(context),
        ),
      ],
    );
  }

  Widget _viewForFamily(BuildContext context) {
    switch (state.kind) {
      case StatKind.ranking:
        return KeyedSubtree(
          key: const ValueKey('ranking'),
          child: StatsCard(child: StatsRankingList(data: state.ranking!)),
        );
      case StatKind.improvement:
        return KeyedSubtree(
          key: const ValueKey('improvement'),
          child: StatsCard(
            child: StatsImprovementView(data: state.improvement!),
          ),
        );
      case StatKind.activity:
        return KeyedSubtree(
          key: const ValueKey('activity'),
          child: StatsCard(child: StatsActivityView(data: state.activity!)),
        );
      case StatKind.judgeRating:
        return KeyedSubtree(
          key: const ValueKey('judgeRating'),
          child: StatsCard(
            child: StatsJudgeRatingView(data: state.judgeRating!),
          ),
        );
      default:
        return KeyedSubtree(
          key: const ValueKey('bucketed'),
          child: StatsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BucketedHeader(state: state),
                const SizedBox(height: 14),
                StatsBarChart(data: state.bucketed!, kind: state.kind),
              ],
            ),
          ),
        );
    }
  }
}

class _BucketedHeader extends StatelessWidget {
  final DebaterStatsState state;
  const _BucketedHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final title = switch (state.kind) {
      StatKind.winRate => context.loc.statsWinRateTitle,
      StatKind.avgScore => context.loc.statsAvgScoreTitle,
      StatKind.bestSpeaker => context.loc.statsBestSpeakerTitle,
      _ => '',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.subtitle(context).copyWith(
            fontWeight: FontWeight.w800,
            color: StatsTheme.textPrimary(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: JadalColors.primaryOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            context.loc.statsDebatesCount(state.bucketed!.totalNDebates),
            style: AppTextStyles.small(context).copyWith(
              fontWeight: FontWeight.w800,
              color: JadalColors.primaryOrange,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThinProgress extends StatelessWidget {
  const _ThinProgress();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        child: LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: Colors.transparent,
          color: JadalColors.primaryOrange,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE53935).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFE53935),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: StatsTheme.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final DebaterStatsState state;
  const _ErrorCard({required this.message, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebaterStatsCubit>();
    return StatsCard(
      child: JadalErrorView(
        compact: true,
        message: FailureText.fromMessage(context, message),
        onRetry: cubit.load,
      ),
    );
  }
}
