import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/activity_stat_model.dart';
import 'stats_theme.dart';

/// The activity/participation score. Deliberately NOT a column chart:
/// the product ask is "review the improvement of activeness over time," so
/// this renders a trend line of the per-bucket totals, headed by the big
/// total, and — the part the raw number can't tell you — a breakdown of what
/// made it: registrations, attendance, viewing, and missed-debate penalties.
class StatsActivityView extends StatelessWidget {
  final ActivityStat data;
  const StatsActivityView({super.key, required this.data});

  static Color signColor(double v) =>
      v >= 0 ? JadalColors.positiveGreen : JadalColors.negativeRed;

  @override
  Widget build(BuildContext context) {
    final color = signColor(data.totalValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: data.totalValue),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              // Arrow + sign, not colour alone.
              (v > 0
                      ? '▲ '
                      : v < 0
                      ? '▼ '
                      : '') +
                  (v >= 0 ? '+' : '') +
                  v.toStringAsFixed(0),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                fontSize: 44,
                color: color,
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            context.loc.statsActivityPoints,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: StatsTheme.textSecondary(context),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // The chart was never "removed": it is gated on ≥2
        // buckets, and the screen used to pin group_by to `none`, which always
        // returns a single all-time bucket. With grouping restored this
        // renders; when a period genuinely has one bucket, say so rather than
        // silently dropping the section.
        if (data.buckets.length >= 2) ...[
          Text(
            context.loc.statsActivityTrend,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w800,
              color: StatsTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 90, child: _TrendLine(buckets: data.buckets)),
          const SizedBox(height: 18),
        ] else ...[
          Text(
            context.loc.statsActivityLongerPeriod,
            style: AppTextStyles.small(context).copyWith(
              fontStyle: FontStyle.italic,
              color: StatsTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 18),
        ],
        Text(
          context.loc.statsActivityBreakdown,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w800,
            color: StatsTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        _BreakdownRows(breakdown: data.totalBreakdown),
        if (data.buckets.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            context.loc.statsActivityByPeriod,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w800,
              color: StatsTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          for (final b in data.buckets) _BucketRow(bucket: b),
        ],
      ],
    );
  }
}

/// The four signal rows: icon + label + count + signed points.
class _BreakdownRows extends StatelessWidget {
  final ActivityBreakdown breakdown;
  const _BreakdownRows({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final rows = <(IconData, String, String, ActivitySignal)>[
      (
        Icons.how_to_reg_rounded,
        loc.statsActivityRegistrations,
        loc.statsActivityCountRegistered(breakdown.registration.count),
        breakdown.registration,
      ),
      (
        Icons.event_available_rounded,
        loc.statsActivityAttendance,
        loc.statsActivityCountAttended(breakdown.attendance.count),
        breakdown.attendance,
      ),
      (
        Icons.visibility_rounded,
        loc.statsActivityWatched,
        loc.statsActivityCountWatched(breakdown.viewing.count),
        breakdown.viewing,
      ),
      (
        Icons.event_busy_rounded,
        loc.statsActivityMissed,
        loc.statsActivityCountMissed(breakdown.penalty.count),
        breakdown.penalty,
      ),
    ];
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(r.$1, size: 18, color: StatsTheme.textSecondary(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.$2,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: StatsTheme.textPrimary(context),
                    ),
                  ),
                ),
                if (r.$4.count > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: Text(
                      r.$3,
                      style: AppTextStyles.small(
                        context,
                      ).copyWith(color: StatsTheme.textSecondary(context)),
                    ),
                  ),
                Text(
                  _signed(r.$4.points),
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: r.$4.points == 0
                        ? StatsTheme.textSecondary(context)
                        : StatsActivityView.signColor(r.$4.points),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One time bucket: period label, its signed total, and a one-line micro
/// breakdown so "what happened in that month" is readable without a tap.
class _BucketRow extends StatelessWidget {
  final ActivityBucket bucket;
  const _BucketRow({required this.bucket});

  @override
  Widget build(BuildContext context) {
    final b = bucket.breakdown;
    final parts = <String>[
      if (b.registration.points != 0) '${_signed(b.registration.points)} reg',
      if (b.attendance.points != 0) '${_signed(b.attendance.points)} att',
      if (b.viewing.points != 0) '${_signed(b.viewing.points)} view',
      if (b.penalty.points != 0) '${_signed(b.penalty.points)} missed',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bucket.label,
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: StatsTheme.textPrimary(context),
                  ),
                ),
                if (parts.isNotEmpty)
                  Text(
                    parts.join(' · '),
                    style: AppTextStyles.small(
                      context,
                    ).copyWith(color: StatsTheme.textSecondary(context)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: StatsActivityView.signColor(
                bucket.value,
              ).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _signed(bucket.value),
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w800,
                color: StatsActivityView.signColor(bucket.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colour must never be the only carrier of meaning. Positive and
/// negative deltas take an arrow **and** a sign, so they stay readable under
/// red–green colour-vision deficiency (where the green and red collapse toward
/// each other) and in greyscale.
String _signed(double v) {
  final arrow = v > 0
      ? '▲ '
      : v < 0
      ? '▼ '
      : '';
  final sign = v >= 0 ? '+' : '';
  return arrow + sign + v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
}

/// A line-with-area trend of the per-bucket totals. Unlike the improvement
/// sparkline (fixed 0–100 score scale), activity points are unbounded and can
/// go negative, so the scale derives from the data with a zero guide line
/// whenever the range crosses it.
class _TrendLine extends StatelessWidget {
  final List<ActivityBucket> buckets;
  const _TrendLine({required this.buckets});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeInOut,
      builder: (context, t, _) => CustomPaint(
        painter: _TrendPainter(
          buckets: buckets,
          progress: t,
          line: JadalColors.primaryOrange,
          fill: JadalColors.primaryOrange.withValues(alpha: 0.16),
          guide: StatsTheme.textSecondary(context).withValues(alpha: 0.35),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<ActivityBucket> buckets;
  final double progress;
  final Color line;
  final Color fill;
  final Color guide;

  _TrendPainter({
    required this.buckets,
    required this.progress,
    required this.line,
    required this.fill,
    required this.guide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final values = buckets.map((b) => b.value).toList();
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    // Always include zero so "no activity" reads as the floor, and pad a flat
    // series so it doesn't divide by zero / hug an edge.
    if (minV > 0) minV = 0;
    if (maxV < 0) maxV = 0;
    if (maxV == minV) maxV = minV + 1;
    final span = maxV - minV;

    final n = buckets.length;
    Offset pointAt(int i) {
      final x = size.width * (i / (n - 1));
      final y = size.height - (values[i] - minV) / span * size.height;
      return Offset(x, y);
    }

    final zeroY = size.height - (0 - minV) / span * size.height;

    // Zero guide line (dashed), only meaningful when in view.
    if (zeroY > 0 && zeroY < size.height) {
      final dash = Paint()
        ..color = guide
        ..strokeWidth = 1;
      const dashW = 4.0;
      for (var x = 0.0; x < size.width; x += dashW * 2) {
        canvas.drawLine(Offset(x, zeroY), Offset(x + dashW, zeroY), dash);
      }
    }

    final shown = (progress * (n - 1)).clamp(0.0, (n - 1).toDouble());
    final full = shown.floor();
    final frac = shown - full;

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i <= full; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    double tipX = pointAt(full).dx;
    if (full < n - 1 && frac > 0) {
      final a = pointAt(full);
      final b = pointAt(full + 1);
      tipX = a.dx + (b.dx - a.dx) * frac;
      path.lineTo(tipX, a.dy + (b.dy - a.dy) * frac);
    }

    // Fill down to the zero line (not the canvas floor) so negative stretches
    // read as dips below zero rather than mountains.
    final baseY = zeroY.clamp(0.0, size.height);
    final area = Path.from(path)
      ..lineTo(tipX, baseY)
      ..lineTo(pointAt(0).dx, baseY)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = line;
    for (var i = 0; i <= full; i++) {
      canvas.drawCircle(pointAt(i), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.progress != progress || old.buckets != buckets;
}
