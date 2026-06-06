import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_gradient_button.dart';
import '../cubits/debate_cubit.dart';
import '../utils/debate_theme.dart';

/// POI speech-bubble: the cloud shape + scale-in animation from the legacy
/// `POICloud`, but with a clean "POI" text label instead of an image (§8.4).
///
/// Gestures: tap → [onTap] (only the main speaker passes a non-null handler);
/// swipe down → the bubble falls off-screen fast (a fun "refuse"), then calls
/// [onRefuse].
class PoiBubble extends StatefulWidget {
  final bool pointsStart; // triangle points toward the card (start side)
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback onRefuse;
  final double size;

  const PoiBubble({
    super.key,
    required this.pointsStart,
    required this.color,
    required this.onRefuse,
    this.onTap,
    this.size = 56,
  });

  @override
  State<PoiBubble> createState() => _PoiBubbleState();
}

class _PoiBubbleState extends State<PoiBubble> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  late final AnimationController _fall = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  bool _falling = false;

  @override
  void dispose() {
    _in.dispose();
    _fall.dispose();
    super.dispose();
  }

  void _refuseWithFall() {
    if (_falling) return;
    setState(() => _falling = true);
    _fall.forward().whenComplete(widget.onRefuse);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onVerticalDragUpdate: (d) {
        if ((d.primaryDelta ?? 0) > 6) _refuseWithFall();
      },
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 0) _refuseWithFall();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_in, _fall]),
        builder: (context, child) {
          final fallV = Curves.easeIn.transform(_fall.value);
          return Transform.translate(
            offset: Offset(0, fallV * 240),
            child: Opacity(
              opacity: (1 - fallV).clamp(0.0, 1.0),
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _in, curve: Curves.easeOutBack),
                child: child,
              ),
            ),
          );
        },
        child: CustomPaint(
          painter: _PoiBubblePainter(widget.color, widget.pointsStart),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: widget.pointsStart ? widget.size * 0.12 : 0,
                  end: widget.pointsStart ? 0 : widget.size * 0.12,
                ),
                child: Text(
                  'POI',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: widget.size * 0.26,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PoiBubblePainter extends CustomPainter {
  final Color color;
  final bool pointsStart;
  _PoiBubblePainter(this.color, this.pointsStart);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final r = size.shortestSide * 0.42;
    final shift = size.width * 0.08;
    final center = Offset(size.width / 2 + (pointsStart ? shift : -shift), size.height / 2);
    canvas.drawCircle(center, r, paint);

    final path = Path();
    final tail = size.width * 0.18;
    final base = size.height * 0.22;
    if (pointsStart) {
      path.moveTo(center.dx - r + 4, center.dy - base / 2);
      path.lineTo(center.dx - r - tail, center.dy);
      path.lineTo(center.dx - r + 4, center.dy + base / 2);
    } else {
      path.moveTo(center.dx + r - 4, center.dy - base / 2);
      path.lineTo(center.dx + r + tail, center.dy);
      path.lineTo(center.dx + r - 4, center.dy + base / 2);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PoiBubblePainter old) =>
      old.color != color || old.pointsStart != pointsStart;
}

/// Shown to the asker after the speaker accepts their POI (§8.4): a mic control
/// + a Done button that returns them to silence.
class PoiAskerMicDialog extends StatelessWidget {
  const PoiAskerMicDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return BlocBuilder<DebateCubit, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateCubit>();
        return AlertDialog(
          backgroundColor: DebateTheme.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            loc.poiYourTurn,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              color: DebateTheme.textPrimary(context),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.poiSpeakNow,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', color: DebateTheme.textSecondary(context)),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: cubit.toggleMic,
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: cubit.isMicEnabled
                      ? JadalColors.primaryBlue.withValues(alpha: 0.18)
                      : JadalColors.judgesGrey.withValues(alpha: 0.18),
                  child: Icon(
                    cubit.isMicEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                    size: 32,
                    color: cubit.isMicEnabled
                        ? JadalColors.primaryBlue
                        : JadalColors.judgesGrey,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            JadalGradientButton(
              text: loc.poiDone,
              width: 140,
              onPressed: () {
                cubit.poiDone();
                Navigator.of(context).maybePop();
              },
            ),
          ],
        );
      },
    );
  }
}
