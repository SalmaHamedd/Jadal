import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/hex_color.dart';
import '../../data/models/debater_stats_models.dart';
import '../cubits/debater_stats_cubit.dart';
import 'stats_theme.dart';

/// The shared filter bar that feeds every stat. It shows only the controls that
/// matter for the current [DebaterStatsState.kind]: grouping + series for the
/// chart stats, ranking order for the list, and the position multi-select +
/// month range for all of them.
class StatsFilterBar extends StatelessWidget {
  final DebaterStatsState state;

  /// MF_FU §8.2 — activity accepts only `from`/`to`/`group_by`; the position,
  /// framework and series dimensions don't exist for it (the repository strips
  /// them). It gets the grouping + period rows and nothing else, instead of the
  /// whole bar being hidden — which is what left `group_by` pinned to `none`
  /// and made the trend chart unreachable.
  final bool periodOnly;

  const StatsFilterBar({
    super.key,
    required this.state,
    this.periodOnly = false,
  });

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
    final loc = context.loc;
    final cubit = context.read<DebaterStatsCubit>();
    final f = state.filter;
    // Activity is bucketed too, it just has no series/dimension controls.
    final showGrouping = state.isBucketed || periodOnly;
    final isBestSpeaker = state.kind == StatKind.bestSpeaker;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart stats: time grouping.
        if (showGrouping)
          _ChipRow(
            label: loc.statsGroupBy,
            children: [
              for (final g in StatsGroupBy.values)
                StatsChip(
                  label: switch (g) {
                    StatsGroupBy.none => loc.statsAllTime,
                    StatsGroupBy.year => loc.statsYear,
                    StatsGroupBy.month => loc.statsMonth,
                  },
                  selected: f.groupBy == g,
                  accent: JadalColors.primaryBlue,
                  onTap: () => cubit.setGroupBy(g),
                ),
            ],
          ),
        // Chart stats: which dimension becomes parallel bars. Follows the
        // active filter dimension (§1.4).
        if (state.isBucketed && !periodOnly)
          _ChipRow(
            label: loc.statsCompare,
            hint: (f.series == StatsSeries.positions && f.positions.length < 2)
                ? loc.statsHintPickPositions
                : (f.series == StatsSeries.frameworks &&
                      f.frameworks.length < 2)
                ? loc.statsHintPickFrameworks
                : null,
            children: [
              StatsChip(
                label: loc.statsCombined,
                selected: f.series == StatsSeries.none,
                accent: JadalColors.primaryBlue,
                onTap: () => cubit.setSeries(StatsSeries.none),
              ),
              if (state.dim == StatsFilterDim.positions)
                StatsChip(
                  label: loc.statsByPosition,
                  selected: f.series == StatsSeries.positions,
                  accent: JadalColors.primaryBlue,
                  onTap: () => cubit.setSeries(StatsSeries.positions),
                )
              else
                StatsChip(
                  label: loc.statsByFramework,
                  selected: f.series == StatsSeries.frameworks,
                  accent: JadalColors.primaryBlue,
                  onTap: () => cubit.setSeries(StatsSeries.frameworks),
                ),
            ],
          ),
        // Ranking: ordering mode.
        if (state.kind == StatKind.ranking && !periodOnly)
          _ChipRow(
            label: loc.statsOrder,
            children: [
              for (final m in RankingMode.values)
                StatsChip(
                  label: switch (m) {
                    RankingMode.top => loc.statsRankTop,
                    RankingMode.bottom => loc.statsRankBottom,
                    RankingMode.latest => loc.statsRankLatest,
                    RankingMode.earliest => loc.statsRankEarliest,
                  },
                  selected: state.rankingMode == m,
                  onTap: () => cubit.setRankingMode(m),
                ),
            ],
          ),
        // §1.4 — the filter dimension: position OR motion framework, never
        // both. Switching clears the other's selection.
        if (!periodOnly) ...[
          _ChipRow(
            label: loc.statsFilterBy,
            children: [
              StatsChip(
                label: loc.statsPositionLabel,
                selected: state.dim == StatsFilterDim.positions,
                accent: JadalColors.primaryOrange,
                onTap: () => cubit.setDim(StatsFilterDim.positions),
              ),
              StatsChip(
                label: loc.statsFrameworkLabel,
                selected: state.dim == StatsFilterDim.frameworks,
                accent: JadalColors.primaryOrange,
                onTap: () => cubit.setDim(StatsFilterDim.frameworks),
              ),
            ],
          ),
          if (state.dim == StatsFilterDim.positions)
            _ChipRow(
              label: loc.statsPositionsLabel,
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
            )
          else if (state.frameworkOptions.isNotEmpty)
            _ChipRow(
              label: loc.statsFrameworksLabel,
              children: [
                for (final fw in state.frameworkOptions)
                  StatsChip(
                    label: fw.name,
                    selected: f.frameworks.contains(fw.id),
                    accent:
                        colorFromHex(fw.colorHex) ?? JadalColors.primaryBlue,
                    onTap: () => cubit.toggleFramework(fw.id),
                  ),
              ],
            ),
        ],
        // Month range (all stats).
        _ChipRow(
          label: loc.statsPeriod,
          hint: (periodOnly && f.groupBy == StatsGroupBy.none)
              ? loc.statsActivityLongerPeriod
              : null,
          children: [
            _MonthButton(
              text: f.from ?? loc.statsFrom,
              onPick: () async {
                final v = await _pickMonth(context, f.from);
                if (v != null) cubit.setRange(from: v);
              },
            ),
            _MonthButton(
              text: f.to ?? loc.statsTo,
              onPick: () async {
                final v = await _pickMonth(context, f.to);
                if (v != null) cubit.setRange(to: v);
              },
            ),
            if (f.from != null ||
                f.to != null ||
                f.positions.isNotEmpty ||
                f.frameworks.isNotEmpty)
              StatsChip(
                label: loc.statsReset,
                selected: false,
                accent: JadalColors.negativeRed,
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
      helpText: context.loc.statsPickMonthHelp,
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
