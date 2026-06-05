import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../data/models/debate_models.dart';
import '../utils/debate_theme.dart';
import '../utils/debate_timeline.dart';

/// Timer chip attached to the main speaker card. Generalized from the legacy
/// `ScalableDebateTimer`: all thresholds come from [timeline] (§8.3 B), and the
/// colour follows the current [DebateTier] (protected/open/extra/timeOff).
class DebateTimerBadge extends StatelessWidget {
  final int elapsedSeconds;
  final DebateTimeline timeline;
  final DebateSide side;
  final double width;
  final double height;

  const DebateTimerBadge({
    super.key,
    required this.elapsedSeconds,
    required this.timeline,
    required this.side,
    this.width = 110,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final dark = DebateTheme.isDark(context);
    final tier = timeline.tierAt(elapsedSeconds);
    final accent = DebateTheme.tierAccent(tier, side, dark);
    final progress =
        (elapsedSeconds / timeline.totalTrackedSeconds).clamp(0.0, 1.0).toDouble();

    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');

    final label = switch (tier) {
      DebateTier.protected => loc.protected,
      DebateTier.open => loc.open,
      DebateTier.extra => loc.extraTime,
      DebateTier.timeOff => loc.time_over,
    };

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DebateTheme.surface(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _TimerBorderPainter(progress: progress, accent: accent, radius: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (tier == DebateTier.protected)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Icon(Icons.lock_rounded, size: 13, color: accent),
                  ),
                Text(
                  '$minutes:$seconds',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: 1.0,
                    color: DebateTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 8.5,
                letterSpacing: 0.4,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerBorderPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final double radius;

  _TimerBorderPainter({required this.progress, required this.accent, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final bg = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, bg);

    if (progress <= 0) return;

    final fg = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(rect.center.dx, rect.top);
    path.lineTo(rect.right - radius, rect.top);
    path.arcToPoint(Offset(rect.right, rect.top + radius), radius: Radius.circular(radius));
    path.lineTo(rect.right, rect.bottom - radius);
    path.arcToPoint(Offset(rect.right - radius, rect.bottom), radius: Radius.circular(radius));
    path.lineTo(rect.left + radius, rect.bottom);
    path.arcToPoint(Offset(rect.left, rect.bottom - radius), radius: Radius.circular(radius));
    path.lineTo(rect.left, rect.top + radius);
    path.arcToPoint(Offset(rect.left + radius, rect.top), radius: Radius.circular(radius));
    path.lineTo(rect.center.dx, rect.top);

    final metric = path.computeMetrics().first;
    canvas.drawPath(metric.extractPath(0, metric.length * progress), fg);
  }

  @override
  bool shouldRepaint(covariant _TimerBorderPainter old) =>
      old.progress != progress || old.accent != accent;
}
