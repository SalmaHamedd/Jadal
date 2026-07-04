import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/debater_stats_models.dart';
import 'stats_theme.dart';

/// Stat 5 — the improvement index. A −50..+50 **scale** (red → neutral → green)
/// with a fixed needle marking where the debater sits (a read-out, not a slider
/// you can drag), an avg-score sparkline, and the component breakdown. Numbers
/// read green when positive and red when negative, matching the scale's ends.
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

  static Color signColor(double v) =>
      v >= 0 ? JadalColors.positiveGreen : JadalColors.negativeRed;

  @override
  Widget build(BuildContext context) {
    final hasIndex = data.hasEnoughHistory;
    final color = hasIndex ? signColor(data.index!) : JadalColors.judgesGrey;

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
          const SizedBox(height: 18),
          _Gauge(index: data.index!),
          const SizedBox(height: 22),
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

/// The static read-out scale: a muted red→neutral→green track with a
/// sign-coloured fill sweeping out from the zero midpoint to the debater's
/// index, topped by a slim caret pointer. Reading it as a measurement (how far
/// from neutral, and which way) — not a slider you can drag. −50/0/+50 labels
/// anchor the scale.
class _Gauge extends StatelessWidget {
  final double index; // −50..+50
  const _Gauge({required this.index});

  static const double _trackH = 9;

  @override
  Widget build(BuildContext context) {
    final fraction = ((index + 50) / 100).clamp(0.0, 1.0);
    final sign = StatsImprovementView.signColor(index);
    final muted = StatsTheme.textSecondary(context);

    return Column(
      children: [
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return TweenAnimationBuilder<double>(
                // Animate out from the neutral midpoint so the fill visibly
                // "grows" toward the score in its direction.
                tween: Tween(begin: 0.5, end: fraction),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) {
                  final mid = w / 2;
                  final x = (w * t).clamp(0.0, w);
                  final fillLeft = x < mid ? x : mid;
                  final fillWidth = (x - mid).abs();
                  const caretW = 13.0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Muted base track — the full scale.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: _trackH,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(_trackH / 2),
                            gradient: LinearGradient(
                              colors: [
                                JadalColors.negativeRed.withValues(alpha: 0.30),
                                muted.withValues(alpha: 0.22),
                                JadalColors.positiveGreen.withValues(alpha: 0.30),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Deviation fill from the zero midpoint to the value.
                      Positioned(
                        left: fillLeft,
                        bottom: 0,
                        child: Container(
                          width: fillWidth.clamp(0.0, w),
                          height: _trackH,
                          decoration: BoxDecoration(
                            color: sign,
                            borderRadius: BorderRadius.circular(_trackH / 2),
                            boxShadow: [
                              BoxShadow(
                                color: sign.withValues(alpha: 0.35),
                                blurRadius: 6,
                                spreadRadius: -1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Subtle zero anchor tick at the midpoint.
                      Positioned(
                        left: mid - 0.5,
                        bottom: -2,
                        child: Container(
                          width: 1,
                          height: _trackH + 4,
                          color: muted.withValues(alpha: 0.55),
                        ),
                      ),
                      // Slim caret pointing down at the value (an annotation, not
                      // a draggable handle).
                      Positioned(
                        left: (x - caretW / 2).clamp(0.0, w - caretW),
                        top: 0,
                        child: CustomPaint(
                          size: const Size(caretW, 8),
                          painter: _CaretPainter(sign),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('−50', style: _scaleStyle(muted)),
            const Spacer(),
            Text('0', style: _scaleStyle(muted)),
            const Spacer(),
            Text('+50', style: _scaleStyle(muted)),
          ],
        ),
      ],
    );
  }

  TextStyle _scaleStyle(Color c) =>
      TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700, color: c);
}

class _CaretPainter extends CustomPainter {
  final Color color;
  _CaretPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CaretPainter old) => old.color != color;
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
    final rows = <(String, double, String)>[
      ('Score trend', c.slopeScore, c.slopeScore.toStringAsFixed(1)),
      ('Win-rate trend', c.slopeWinrate, c.slopeWinrate.toStringAsFixed(2)),
      ('Consistency', c.consistency, c.consistency.toStringAsFixed(2)),
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
                  r.$3,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: StatsImprovementView.signColor(r.$2),
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
