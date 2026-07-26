import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/attendance_stat_model.dart';
import 'stats_theme.dart';

/// A single-series rate-over-time chart for attendance (§6.5) — deliberately
/// standalone rather than reusing [StatsBarChart]/[StatKind], since this data
/// shape (a plain 0–1 rate + attended/selected counts, no framework/position/
/// team series dimension) doesn't fit that machinery without extending it,
/// and this is explicitly a "one chart is enough" stat, not a 5-tab feature.
class AttendanceBarChart extends StatelessWidget {
  final List<AttendanceBucket> buckets;
  const AttendanceBarChart({super.key, required this.buckets});

  static const double _chartHeight = 170;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text('No data yet.',
              style: TextStyle(fontFamily: 'Cairo', color: StatsTheme.textSecondary(context))),
        ),
      );
    }
    return SizedBox(
      height: _chartHeight + 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [for (final b in buckets) _Bar(bucket: b, chartHeight: _chartHeight)],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final AttendanceBucket bucket;
  final double chartHeight;
  const _Bar({required this.bucket, required this.chartHeight});

  Color _color(double rate) {
    if (rate >= 0.8) return JadalColors.positiveGreen;
    if (rate >= 0.5) return JadalColors.primaryOrange;
    return JadalColors.negativeRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(bucket.rate);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: bucket.rate.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          final barHeight = (chartHeight - 30) * t;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(t * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: StatsTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 26,
                height: barHeight.clamp(2.0, chartHeight),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withValues(alpha: 0.6)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 42,
                child: Text(
                  bucket.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: StatsTheme.textSecondary(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
