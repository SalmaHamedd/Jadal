import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../di/injection_container.dart' as di;
import '../../domain/entities/statistics_models.dart';
import '../../domain/repositories/debate_repositories.dart';
import '../cubits/statistics_cubit.dart';
import '../widgets/arabic_format.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StatisticsCubit>(
      create: (_) => StatisticsCubit(di.sl<StatisticsRepository>())..load(),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _TabSwitcher(current: state.tab),
              Expanded(
                child: state.tab == StatisticsTab.general
                    ? _GeneralView(stats: state.general!)
                    : _PersonalView(stats: state.personal!),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final StatisticsTab current;
  const _TabSwitcher({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (final t in StatisticsTab.values)
            Expanded(
              child: GestureDetector(
                onTap: () => context.read<StatisticsCubit>().setTab(t),
                child: Container(
                  margin: EdgeInsetsDirectional.only(
                      end: t == StatisticsTab.general ? 6 : 0,
                      start: t == StatisticsTab.personal ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: t == current
                        ? JadalColors.primaryOrange
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t == StatisticsTab.general ? 'عام' : 'شخصي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      color: t == current
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GeneralView extends StatelessWidget {
  final GeneralStatistics stats;
  const _GeneralView({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'إجمالي المناظرات',
                value: '${stats.totalDebates}',
                color: JadalColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'متوسط نسبة الفوز',
                value: '${(_avgWinRate(stats) * 100).toStringAsFixed(0)}%',
                color: JadalColors.primaryOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle('نسبة الفوز حسب الإطار'),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1,
              barTouchData: BarTouchData(enabled: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 0.25,
                    getTitlesWidget: (value, meta) => Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(fontSize: 10, fontFamily: 'Cairo'),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= stats.winRateByFramework.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(stats.winRateByFramework[i].framework,
                            style: const TextStyle(
                                fontSize: 10, fontFamily: 'Cairo')),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 0; i < stats.winRateByFramework.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: stats.winRateByFramework[i].winRate,
                      color: JadalColors.primaryOrange,
                      width: 18,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle('أفضل ١٠ مناظرين'),
        const SizedBox(height: 8),
        for (int i = 0; i < stats.leaderboard.length; i++)
          _LeaderRow(rank: i + 1, entry: stats.leaderboard[i]),
      ],
    );
  }

  double _avgWinRate(GeneralStatistics s) {
    if (s.winRateByFramework.isEmpty) return 0;
    final t = s.winRateByFramework.fold<double>(0, (sum, e) => sum + e.winRate);
    return t / s.winRateByFramework.length;
  }
}

class _PersonalView extends StatelessWidget {
  final PersonalStatistics stats;
  const _PersonalView({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _SectionTitle('نسبة الفوز'),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: JadalColors.primaryOrange,
                  value: stats.winRate * 100,
                  title: '${(stats.winRate * 100).toStringAsFixed(0)}%',
                  radius: 36,
                  titleStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w800),
                ),
                PieChartSectionData(
                  color: JadalColors.primaryBlue.withValues(alpha: 0.6),
                  value: (1 - stats.winRate) * 100,
                  title: '',
                  radius: 32,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SectionTitle('تطور الدرجات (آخر ٥ مناظرات)'),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 60, maxY: 100,
              titlesData: const FlTitlesData(
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < stats.scoreTrend.length; i++)
                      FlSpot(i.toDouble(), stats.scoreTrend[i].toDouble()),
                  ],
                  isCurved: true,
                  color: JadalColors.primaryOrange,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SectionTitle('سجل المناظرات'),
        const SizedBox(height: 8),
        for (final h in stats.history) _HistoryRow(entry: h),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 24)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800));
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  const _LeaderRow({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? JadalColors.primaryOrange
                  : JadalColors.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$rank',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: rank <= 3 ? Colors.white : JadalColors.primaryBlue)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry.name,
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Text('${entry.totalScore}',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${entry.wins} فوز',
                style: const TextStyle(
                    fontFamily: 'Cairo', color: Colors.green, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final DebateHistoryEntry entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            entry.win ? Icons.emoji_events : Icons.flag_outlined,
            color: entry.win ? Colors.amber.shade700 : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(formatArabicDateTime(entry.date),
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Text('${entry.score}',
              style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
