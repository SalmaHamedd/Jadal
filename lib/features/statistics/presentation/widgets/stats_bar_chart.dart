import 'package:flutter/material.dart';

import '../../data/models/debater_stats_models.dart';
import 'stats_theme.dart';

/// Horizontal footprint of a single bar = caption width (28) + 2×padding (5).
/// Groups are sized as `barCount × _kBarSlot` so every bar fits exactly and the
/// group never overflows — extra bars just widen the group and scroll.
const double _kBarSlot = 38;
const double _kBarCaptionWidth = 28;
const double _kBarHPad = 5;

/// Vertical space reserved under the plot for the x-axis labels, and inside the
/// plot for the value caption above each bar. Both are HARD bounds: the label /
/// caption render inside fixed-height boxes with a scale-down fit, so no font
/// metric (Cairo is tall) or text scale can ever overflow the chart's bottom.
const double _kLabelSpace = 42;
const double _kCaptionH = 16;

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
          height: _chartHeight + _kLabelSpace,
          child: Stack(
            children: [
              Positioned.fill(
                  bottom: _kLabelSpace, child: const _GridLines(max: _axisMax)),
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
    // Each group is wide enough that its (two-line) label is readable — so only
    // ~3–4 buckets show at once and the rest scroll, instead of cramming many
    // unreadable columns. Multi-series groups grow with their bar count: we size
    // the group to fit *every* bar (each bar's footprint is 20px + 2×7 padding =
    // 34px) with no upper cap, so when comparing by position the group simply
    // gets wider and the outer horizontal scroll takes over — bars never spill
    // past the box (the old 360 cap caused the out-of-bounds overflow).
    final groupWidth = (keys.length * _kBarSlot).clamp(80.0, double.infinity);
    return SizedBox(
      width: groupWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: chartHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 6),
          // Fixed-height slot + scale-down fit → the (two-line) label can never
          // spill past the chart's bottom, whatever the font/scale.
          SizedBox(
            height: _kLabelSpace - 6,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _BucketLabel(raw: bucket.label),
            ),
          ),
        ],
      ),
    );
  }
}

/// The x-axis label for a bucket. A `YYYY-MM` bucket renders as the month name
/// over the year (e.g. "May" / "2025"); a `YYYY` bucket is just the year; and
/// the `all` bucket reads "All time".
class _BucketLabel extends StatelessWidget {
  final String raw;
  const _BucketLabel({required this.raw});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final primary = StatsTheme.textPrimary(context);
    final muted = StatsTheme.textSecondary(context);

    final parts = raw.split('-');
    if (parts.length == 2 &&
        int.tryParse(parts[0]) != null &&
        int.tryParse(parts[1]) != null) {
      final m = int.parse(parts[1]).clamp(1, 12);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _months[m - 1],
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: primary,
            ),
          ),
          Text(
            parts[0],
            style: TextStyle(
                fontFamily: 'Cairo', fontSize: 10, height: 1.15, color: muted),
          ),
        ],
      );
    }

    final text = raw.toLowerCase() == 'all' ? 'All time' : raw;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: primary,
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
      padding: const EdgeInsets.symmetric(horizontal: _kBarHPad),
      child: TweenAnimationBuilder<double>(
        // Animating `end` makes the bar grow on first paint and *morph* to the
        // new height whenever the filters change the value.
        tween: Tween<double>(begin: 0, end: fraction),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          // Caption slot (_kCaptionH) + 4 gap + bar ≤ chartHeight, always.
          final maxBar = chartHeight - _kCaptionH - 4;
          final barHeight = (maxBar * t).clamp(2.0, maxBar);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Caption fades in as the bar approaches full height. Constrained
              // to the bar's slot (width) AND a fixed-height box with scale-down
              // fit (height) so a wide value / tall font can never overflow.
              Opacity(
                opacity: (t * 1.4).clamp(0.0, 1.0),
                child: SizedBox(
                  width: _kBarCaptionWidth,
                  height: _kCaptionH,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      entry.caption(kind),
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: StatsTheme.textPrimary(context),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: barHeight,
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
