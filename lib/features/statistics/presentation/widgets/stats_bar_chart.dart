import 'package:flutter/material.dart';

import '../../data/models/debater_stats_models.dart';
import 'stats_theme.dart';

/// A grouped bar chart for the bucketed stats (win-rate / avg-score /
/// best-speaker). The whole point is the *motion*: every bar's height is driven
/// by a [TweenAnimationBuilder], so when the filter changes and new numbers
/// arrive the bars smoothly morph from the old values to the new ones instead of
/// snapping — the user can literally watch the data change.
class StatsBarChart extends StatelessWidget {
  final BucketedStat data;
  final StatKind kind;
  const StatsBarChart({super.key, required this.data, required this.kind});

  static const double _chartHeight = 190;
  static const double _axisMax = 100; // win% / score(0–100) / best-speaker rate%

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _EmptyChart(text: 'No data for these filters yet.');
    }
    final keys = data.seriesKeys;
    final multiSeries = keys.length > 1;
    final colorOf = <String, Color>{
      for (var i = 0; i < keys.length; i++) keys[i].key: StatsTheme.seriesColor(i),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend (only meaningful when there are parallel series).
        if (multiSeries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final k in keys) _LegendDot(color: colorOf[k.key]!, label: k.label),
              ],
            ),
          ),
        // Plot: y-axis gridlines behind, scrollable bucket groups in front.
        SizedBox(
          height: _chartHeight + 34,
          child: Stack(
            children: [
              Positioned.fill(bottom: 34, child: const _GridLines(max: _axisMax)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final bucket in data.buckets)
                      _BucketGroup(
                        bucket: bucket,
                        kind: kind,
                        keys: keys,
                        colorOf: colorOf,
                        chartHeight: _chartHeight,
                        axisMax: _axisMax,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BucketGroup extends StatelessWidget {
  final StatBucket bucket;
  final StatKind kind;
  final List<({String key, String label})> keys;
  final Map<String, Color> colorOf;
  final double chartHeight;
  final double axisMax;

  const _BucketGroup({
    required this.bucket,
    required this.kind,
    required this.keys,
    required this.colorOf,
    required this.chartHeight,
    required this.axisMax,
  });

  @override
  Widget build(BuildContext context) {
    // Align this bucket's bars to the chart's series order so colours stay put.
    final byKey = {for (final s in bucket.series) s.key: s};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final k in keys)
                  if (byKey[k.key] case final entry?)
                    _Bar(
                      entry: entry,
                      kind: kind,
                      color: colorOf[k.key]!,
                      chartHeight: chartHeight,
                      axisMax: axisMax,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: keys.length * 30,
            child: Text(
              bucket.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: StatsTheme.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final StatSeriesEntry entry;
  final StatKind kind;
  final Color color;
  final double chartHeight;
  final double axisMax;

  const _Bar({
    required this.entry,
    required this.kind,
    required this.color,
    required this.chartHeight,
    required this.axisMax,
  });

  @override
  Widget build(BuildContext context) {
    final value = entry.plotted(kind).clamp(0, axisMax).toDouble();
    final fraction = axisMax <= 0 ? 0.0 : value / axisMax;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: TweenAnimationBuilder<double>(
        // Animating `end` makes the bar grow on first paint and *morph* to the
        // new height whenever the filters change the value.
        tween: Tween<double>(begin: 0, end: fraction),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          final barHeight = (chartHeight - 22) * t;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Caption fades in as the bar approaches full height.
              Opacity(
                opacity: (t * 1.4).clamp(0.0, 1.0),
                child: Text(
                  entry.caption(kind),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: StatsTheme.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: barHeight.clamp(2.0, chartHeight),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withValues(alpha: 0.65)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Horizontal 0/25/50/75/100 gridlines with left-edge labels.
class _GridLines extends StatelessWidget {
  final double max;
  const _GridLines({required this.max});

  @override
  Widget build(BuildContext context) {
    final muted = StatsTheme.textSecondary(context);
    const steps = 4;
    return Column(
      children: [
        for (var i = 0; i <= steps; i++) ...[
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${(max - max * i / steps).round()}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    color: muted.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(height: 1, color: muted.withValues(alpha: 0.12)),
              ),
            ],
          ),
          if (i != steps) const Spacer(),
        ],
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: StatsTheme.textPrimary(context),
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String text;
  const _EmptyChart({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 44, color: StatsTheme.textSecondary(context)),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', color: StatsTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }
}
