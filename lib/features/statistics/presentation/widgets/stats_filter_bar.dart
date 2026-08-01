import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/debater_stats_models.dart';
import '../cubits/debater_stats_cubit.dart';
import 'stats_theme.dart';

/// The shared filter bar that feeds every stat. It shows only the controls that
/// matter for the current [DebaterStatsState.kind]: grouping + series for the
/// chart stats, ranking order for the list, and the position multi-select +
/// month range for all of them.
class StatsFilterBar extends StatelessWidget {
  final DebaterStatsState state;
  const StatsFilterBar({super.key, required this.state});

  // Slot positions. Reply codes (PR, OR) are invalid on best-speaker (422), so
  // they're disabled for that stat.
  static const _positions = <({String code, String label, bool reply})>[
    (code: 'P1', label: 'P1', reply: false),
    (code: 'P2', label: 'P2', reply: false),
    (code: 'P3', label: 'P3', reply: false),
    (code: 'PR', label: 'P-Reply', reply: true),
    (code: 'O1', label: 'O1', reply: false),
    (code: 'O2', label: 'O2', reply: false),
    (code: 'O3', label: 'O3', reply: false),
    (code: 'OR', label: 'O-Reply', reply: true),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebaterStatsCubit>();
    final f = state.filter;
    final isBucketed = state.isBucketed;
    final isBestSpeaker = state.kind == StatKind.bestSpeaker;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart stats: time grouping.
        if (isBucketed)
          _ChipRow(
            label: 'Group by',
            children: [
              for (final g in StatsGroupBy.values)
                StatsChip(
                  label: switch (g) {
                    StatsGroupBy.none => 'All time',
                    StatsGroupBy.year => 'Year',
                    StatsGroupBy.month => 'Month',
                  },
                  selected: f.groupBy == g,
                  accent: JadalColors.primaryBlue,
                  onTap: () => cubit.setGroupBy(g),
                ),
            ],
          ),
        // Chart stats: which dimension becomes parallel bars.
        if (isBucketed)
          _ChipRow(
            label: 'Compare',
            hint: f.series == StatsSeries.positions && f.positions.length < 2
                ? 'Pick 2+ positions below to split the bars'
                : null,
            children: [
              StatsChip(
                label: 'Combined',
                selected: f.series == StatsSeries.none,
                accent: JadalColors.primaryBlue,
                onTap: () => cubit.setSeries(StatsSeries.none),
              ),
              StatsChip(
                label: 'By position',
                selected: f.series == StatsSeries.positions,
                accent: JadalColors.primaryBlue,
                onTap: () => cubit.setSeries(StatsSeries.positions),
              ),
            ],
          ),
        // Ranking: ordering mode.
        if (state.kind == StatKind.ranking)
          _ChipRow(
            label: 'Order',
            children: [
              for (final m in RankingMode.values)
                StatsChip(
                  label: switch (m) {
                    RankingMode.top => 'Top',
                    RankingMode.bottom => 'Bottom',
                    RankingMode.latest => 'Latest',
                    RankingMode.earliest => 'Earliest',
                  },
                  selected: state.rankingMode == m,
                  onTap: () => cubit.setRankingMode(m),
                ),
            ],
          ),
        // Positions (all stats).
        _ChipRow(
          label: 'Positions',
          children: [
            for (final p in _positions)
              StatsChip(
                label: p.label,
                selected: f.positions.contains(p.code),
                enabled: !(isBestSpeaker && p.reply),
                accent: JadalColors.primaryBlue,
                onTap: () => cubit.togglePosition(p.code),
              ),
          ],
        ),
        // Month range (all stats).
        _ChipRow(
          label: 'Period',
          children: [
            _MonthButton(
              text: f.from ?? 'From',
              onPick: () async {
                final v = await _pickMonth(context, f.from);
                if (v != null) cubit.setRange(from: v);
              },
            ),
            _MonthButton(
              text: f.to ?? 'To',
              onPick: () async {
                final v = await _pickMonth(context, f.to);
                if (v != null) cubit.setRange(to: v);
              },
            ),
            if (f.from != null || f.to != null || f.positions.isNotEmpty)
              StatsChip(
                label: 'Reset',
                selected: false,
                accent: const Color(0xFFE53935),
                onTap: cubit.clearFilters,
              ),
          ],
        ),
      ],
    );
  }

  Future<String?> _pickMonth(BuildContext context, String? current) async {
    final now = DateTime.now();
    DateTime initial = now;
    if (current != null) {
      final parts = current.split('-');
      if (parts.length == 2) {
        initial = DateTime(
          int.tryParse(parts[0]) ?? now.year,
          int.tryParse(parts[1]) ?? 1,
        );
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 6),
      lastDate: now,
      helpText: 'Pick a month (day is ignored)',
    );
    if (picked == null) return null;
    return '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final String? hint;
  final List<Widget> children;
  const _ChipRow({required this.label, this.hint, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.small(context).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: StatsTheme.textSecondary(context),
                ),
              ),
              if (hint != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    hint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small(context).copyWith(
                      fontStyle: FontStyle.italic,
                      color: JadalColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i != 0) const SizedBox(width: 8),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPick;
  const _MonthButton({required this.text, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StatsTheme.isDark(context)
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 15,
                color: StatsTheme.textSecondary(context),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: StatsTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
