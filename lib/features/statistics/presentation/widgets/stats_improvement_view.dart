import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/debater_stats_models.dart';
import 'stats_theme.dart';

/// Stat 5 — the improvement index. A horizontal −50..+50 meter with an animated
/// thumb at the index (coloured by band), an avg-score sparkline that draws
/// itself in, and the component breakdown. Falls back to a friendly empty state
/// when there isn't enough history, while still showing the sparkline.
class StatsImprovementView extends StatelessWidget {
  final ImprovementStat data;
  const StatsImprovementView({super.key, required this.data});

  static const _bandLabels = {
    'strong_upward': 'Strong upward',
    'improving': 'Improving',
    'stable': 'Stable',
    'regressing': 'Regressing',
    'sharp_decline': 'Sharp decline',
  };

  Color _bandColor(String? band) => switch (band) {
        'strong_upward' => const Color(0xFF2E9E5B),
        'improving' => const Color(0xFF5BB97A),
        'stable' => JadalColors.judgesGrey,
        'regressing' => const Color(0xFFE8954B),
        'sharp_decline' => const Color(0xFFE53935),
        _ => JadalColors.judgesGrey,
      };

  @override
  Widget build(BuildContext context) {
    final hasIndex = data.hasEnoughHistory;
    final color = _bandColor(data.band);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasIndex) ...[
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: data.index!),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                (v >= 0 ? '+' : '') + v.toStringAsFixed(1),
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
              _bandLabels[data.band] ?? (data.band ?? ''),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Meter(index: data.index!, color: color),
          const SizedBox(height: 20),
        ] else ...[
          _InsufficientBanner(reason: data.reason),
          const SizedBox(height: 16),
        ],
        Text(
          'Average score trend',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: StatsTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(height: 90, child: _Sparkline(buckets: data.buckets)),
        if (hasIndex && data.components != null) ...[
          const SizedBox(height: 18),
          _Components(c: data.components!),
        ],
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  final double index; // −50..+50
  final Color color;
  const _Meter({required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = ((index + 50) / 100).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) {
        return SizedBox(
          height: 26,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), JadalColors.judgesGrey, Color(0xFF2E9E5B)],
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => Padding(
                  padding: EdgeInsets.only(left: (c.maxWidth - 22) * t),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<ImprovementBucket> buckets;
  const _Sparkline({required this.buckets});

  @override
  Widget build(BuildContext context) {
    if (buckets.length < 2) {
      return Center(
        child: Text(
          'Not enough points to chart yet.',
          style: TextStyle(fontFamily: 'Cairo', color: StatsTheme.textSecondary(context)),
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeInOut,
      builder: (context, t, _) => CustomPaint(
        painter: _SparklinePainter(
          buckets: buckets,
          progress: t,
          line: JadalColors.primaryOrange,
          fill: JadalColors.primaryOrange.withValues(alpha: 0.16),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<ImprovementBucket> buckets;
  final double progress;
  final Color line;
  final Color fill;

  _SparklinePainter({
    required this.buckets,
    required this.progress,
    required this.line,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const minV = 0.0;
    const maxV = 100.0;
    final n = buckets.length;
    Offset pointAt(int i) {
      final x = size.width * (i / (n - 1));
      final v = buckets[i].avgScore.clamp(minV, maxV);
      final y = size.height - (v - minV) / (maxV - minV) * size.height;
      return Offset(x, y);
    }

    // Reveal the line left-to-right by drawing only up to `progress`.
    final shown = (progress * (n - 1)).clamp(0.0, (n - 1).toDouble());
    final full = shown.floor();
    final frac = shown - full;

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i <= full; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    if (full < n - 1 && frac > 0) {
      final a = pointAt(full);
      final b = pointAt(full + 1);
      path.lineTo(a.dx + (b.dx - a.dx) * frac, a.dy + (b.dy - a.dy) * frac);
    }

    // Area fill under the revealed segment.
    final last = full < n - 1 && frac > 0
        ? Offset(
            pointAt(full).dx + (pointAt(full + 1).dx - pointAt(full).dx) * frac,
            size.height,
          )
        : Offset(pointAt(full).dx, size.height);
    final area = Path.from(path)
      ..lineTo(last.dx, size.height)
      ..lineTo(pointAt(0).dx, size.height)
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

    // Dots on revealed points.
    final dot = Paint()..color = line;
    for (var i = 0; i <= full; i++) {
      canvas.drawCircle(pointAt(i), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.progress != progress || old.buckets != buckets;
}

class _Components extends StatelessWidget {
  final ImprovementComponents c;
  const _Components({required this.c});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Score trend', c.slopeScore.toStringAsFixed(1)),
      ('Win-rate trend', c.slopeWinrate.toStringAsFixed(2)),
      ('Consistency', c.consistency.toStringAsFixed(2)),
    ];
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  r.$1,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    color: StatsTheme.textSecondary(context),
                  ),
                ),
                Text(
                  r.$2,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: StatsTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InsufficientBanner extends StatelessWidget {
  final String? reason;
  const _InsufficientBanner({this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JadalColors.primaryOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JadalColors.primaryOrange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline_rounded, color: JadalColors.primaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Not enough history yet to score improvement — debate a few more rounds and this lights up.',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
                height: 1.4,
                color: StatsTheme.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
