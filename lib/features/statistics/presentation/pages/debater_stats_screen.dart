import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../di/injection_container.dart' as di;
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/models/debater_stats_models.dart';
import '../../data/repositories/debater_stats_repository.dart';
import '../cubits/debater_stats_cubit.dart';
import '../utils/stats_excel_exporter.dart';
import '../widgets/stats_activity_view.dart';
import '../widgets/stats_bar_chart.dart';
import '../widgets/stats_filter_bar.dart';
import '../widgets/stats_improvement_view.dart';
import '../widgets/stats_ranking_list.dart';
import '../widgets/stats_theme.dart';

/// The Debater Statistics screen. Pass a [debaterId] to view a specific debater
/// (coach/admin); omit it to resolve the signed-in user from their profile —
/// which is how the temporary entry point on the debates list reaches it.
class DebaterStatsScreen extends StatefulWidget {
  final int? debaterId;
  final String? debaterName;
  const DebaterStatsScreen({super.key, this.debaterId, this.debaterName});

  @override
  State<DebaterStatsScreen> createState() => _DebaterStatsScreenState();
}

class _DebaterStatsScreenState extends State<DebaterStatsScreen> {
  int? _id;
  String? _name;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.debaterId != null) {
      _id = widget.debaterId;
      _name = widget.debaterName;
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
        backgroundColor:
            StatsTheme.isDark(context) ? JadalColors.darkBackground : JadalColors.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Statistics',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
        ),
        body: JadalGradientBackground(child: _resolving(context)),
      );
    }
    return BlocProvider(
      create: (_) => DebaterStatsCubit(
        repo: di.sl<DebaterStatsRepository>(),
        debaterId: _id!,
      )..load(),
      child: _StatsScaffold(debaterName: _name),
    );
  }

  Widget _resolving(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52, color: JadalColors.judgesGrey),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', color: StatsTheme.textPrimary(context)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _error = null;
                  _resolveSelf();
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

}

/// The ready-state scaffold (inside the BlocProvider). Holds the app bar with
/// the "export to Excel sheet" action and the scrollable stats body.
class _StatsScaffold extends StatelessWidget {
  final String? debaterName;
  const _StatsScaffold({required this.debaterName});

  bool _hasData(DebaterStatsState s) => switch (s.kind) {
        StatKind.ranking => s.ranking != null,
        StatKind.improvement => s.improvement != null,
        StatKind.activity => s.activity != null,
        _ => s.bucketed != null,
      };

  Future<void> _export(BuildContext context, DebaterStatsState state) async {
    final messenger = ScaffoldMessenger.of(context);
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
      );
      if (bytes == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Nothing to export yet')));
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${StatsExcelExporter.fileName(state.kind)}');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Jadal debate analysis sheet',
        subject: 'Jadal debate analysis',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          StatsTheme.isDark(context) ? JadalColors.darkBackground : JadalColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          debaterName == null ? 'Statistics' : '$debaterName · Statistics',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
        ),
        actions: [
          BlocBuilder<DebaterStatsCubit, DebaterStatsState>(
            builder: (context, state) {
              final canExport = _hasData(state);
              return IconButton(
                tooltip: 'Export sheet',
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: canExport ? () => _export(context, state) : null,
              );
            },
          ),
        ],
      ),
      body: JadalGradientBackground(child: const _StatsView()),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebaterStatsCubit, DebaterStatsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _KindSelector(active: state.kind),
            const SizedBox(height: 16),
            StatsCard(child: StatsFilterBar(state: state)),
            const SizedBox(height: 16),
            _Content(state: state),
          ],
        );
      },
    );
  }
}

/// The five stat tabs as a horizontally-scrollable segmented selector.
class _KindSelector extends StatelessWidget {
  final StatKind active;
  const _KindSelector({required this.active});

  static const _items = <({StatKind kind, String label, IconData icon})>[
    (kind: StatKind.winRate, label: 'Win rate', icon: Icons.percent_rounded),
    (kind: StatKind.avgScore, label: 'Avg score', icon: Icons.speed_rounded),
    (kind: StatKind.bestSpeaker, label: 'Best speaker', icon: Icons.workspace_premium_rounded),
    (kind: StatKind.ranking, label: 'Ranking', icon: Icons.format_list_numbered_rounded),
    (kind: StatKind.improvement, label: 'Improvement', icon: Icons.trending_up_rounded),
    (kind: StatKind.activity, label: 'Activity', icon: Icons.local_fire_department_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebaterStatsCubit>();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = _items[i];
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
                          colors: [JadalColors.primaryBlue, JadalColors.primaryOrange],
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
                          color: selected ? Colors.white : StatsTheme.textSecondary(context),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                            color: selected ? Colors.white : StatsTheme.textSecondary(context),
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
        _ => state.bucketed != null,
      };

  @override
  Widget build(BuildContext context) {
    // Nothing for this stat yet → full loader / first-load error.
    if (!_hasData) {
      if (state.status == StatsStatus.error) {
        return _ErrorCard(message: state.error ?? 'Something went wrong', state: state);
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
          _ErrorBanner(message: state.error ?? 'Could not update with these filters'),
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
          child: StatsCard(child: StatsImprovementView(data: state.improvement!)),
        );
      case StatKind.activity:
        return KeyedSubtree(
          key: const ValueKey('activity'),
          child: StatsCard(child: StatsActivityView(data: state.activity!)),
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
      StatKind.winRate => 'Win rate',
      StatKind.avgScore => 'Average score',
      StatKind.bestSpeaker => 'Best-speaker rate',
      _ => '',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 15,
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
            '${state.bucketed!.totalNDebates} debates',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
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
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE53935), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontFamily: 'Cairo', color: StatsTheme.textPrimary(context)),
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
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 44, color: JadalColors.judgesGrey),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', color: StatsTheme.textPrimary(context)),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: cubit.load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
