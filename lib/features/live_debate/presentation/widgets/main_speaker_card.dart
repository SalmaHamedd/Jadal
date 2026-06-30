import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubits/connection_cubit.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';
import '../utils/debate_timeline.dart';
import 'debate_timer.dart';
import 'jadal_video_card.dart';

/// The visual focus of Layout 2 (§8.3 B): a large rounded card for the current
/// speaker with the timer attached. Coloured by the speaker's side (prop=blue,
/// opp=orange) and the current timer tier.
class MainSpeakerCard extends StatelessWidget {
  const MainSpeakerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return BlocBuilder<DebateController, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateController>();
        final dark = DebateTheme.isDark(context);
        final slot = cubit.currentSlot;

        // C3: the intro phase (live session started, no speech yet) shows the
        // chair in the main card to welcome/introduce — no timer.
        if (cubit.isIntro) {
          return _IntroCard(
            hostId: cubit.introHostId ?? '',
            hostName: cubit.introHostName,
            label: loc.introductionsLabel,
          );
        }
        if (slot == null) {
          return _IdleCard(message: loc.tapNextToStart);
        }

        final side = slot.side;
        final tier = cubit.currentTier;
        final accent = DebateTheme.tierAccent(tier, side, dark);
        final sideColor = DebateTheme.sideColor(side);
        final isOver = tier == DebateTier.timeOff;
        // Timer ring (§U4b): corners alternate side colour (top-right/bottom-left)
        // with the base colour (top-left/bottom-right) — dark base in light theme,
        // light base in dark theme — at ~80% alpha. Time-over paints it all red.
        final cornerBase = dark
            ? Color.lerp(sideColor, Colors.white, 0.55)!
            : JadalColors.deepBlue;
        final ringSide = sideColor.withValues(alpha: 0.8);
        final ringCorner = cornerBase.withValues(alpha: 0.8);
        final ringMid = Color.lerp(ringSide, ringCorner, 0.5)!;
        final ringRed = const Color(0xFFE53935).withValues(alpha: 0.85);
        final SweepGradient ringGradient = isOver
            ? SweepGradient(colors: [ringRed, ringRed])
            : SweepGradient(
                colors: [ringMid, ringCorner, ringSide, ringCorner, ringSide, ringMid],
                stops: const [0.0, 0.125, 0.375, 0.625, 0.875, 1.0],
              );
        final speaker = cubit.debaterAt(side, slot.orderIndex);
        final speakerPresent = cubit.isUserPresent(speaker.id);
        const cardRadius = widgetBorderRadius + 4;
        final total = cubit.timeline.totalTrackedSeconds;
        final progress = total <= 0
            ? 0.0
            : (cubit.elapsedSeconds / total).clamp(0.0, 1.0).toDouble();

        return LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            return Stack(
              // Clip.none so the chair's stop/resume button can straddle the
              // bottom edge (its lower half sits below the card).
              clipBehavior: Clip.none,
              children: [
                // Neutral card surface (§11) — the side colour now lives only in
                // the animated progress ring, not the card body.
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    // Same radius as the card → no light hairline at the corners.
                    // Render the ACTUAL current speaker's media (local or remote),
                    // not always the local user — the old code wired the local
                    // camera onto whoever held the floor.
                    child: JadalVideoCard(
                      name: speaker.name,
                      participantId: speaker.id,
                      bgColor: DebateTheme.floatingCard(context),
                      showVideo: cubit.showVideoForUser(speaker.id),
                      videoTrack: cubit.videoTrackForUser(speaker.id),
                      isMicEnabled: cubit.micOnForUser(speaker.id),
                      isSpeaking: cubit.speakingForUser(speaker.id),
                      micLevel: cubit.isLocalUserId(speaker.id)
                          ? () => cubit.localAudioLevel
                          : null,
                      micActiveColor: sideColor,
                      mainAxis: h,
                      borderRadius: cardRadius,
                    ),
                  ),
                ),
                // The chair advanced to a speaker who isn't in the room yet →
                // make that explicit instead of showing a silent avatar.
                if (!speakerPresent)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_off_outlined,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                loc.notJoinedYet,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // The timer rendered AS a gradient animated border (§11): a
                // progress ring (blue/orange by side) that fills with the speech.
                Positioned.fill(
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => CustomPaint(
                        painter: _ProgressRingPainter(
                          progress: value,
                          gradient: ringGradient,
                          trackColor: accent.withValues(alpha: 0.16),
                          radius: cardRadius,
                          stroke: 4,
                        ),
                      ),
                    ),
                  ),
                ),
                // Role chip (top-center).
                PositionedDirectional(
                  top: 12,
                  start: 0,
                  end: 0,
                  child: Center(child: _RoleChip(label: cubit.roleLabelForSlot(slot), color: accent)),
                ),
                // Timer (top-start) — always visible.
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: DebateTimerBadge(
                    elapsedSeconds: cubit.elapsedSeconds,
                    timeline: cubit.timeline,
                    side: side,
                    isReply: slot.isReply,
                  ),
                ),
                // C1 / Update 1: chair-only stop/resume timer button, straddling
                // the bottom-centre edge. It appears/disappears (animated) together
                // with the tool bar — so when the bar is hidden the button is too,
                // and the tap that reveals the bar can't be mistaken for a (missed)
                // press on a button that wouldn't have stopped the timer anyway.
                if (cubit.canControlTimer)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -22,
                    child: Center(
                      child: BlocBuilder<ConnectionCubit, ConnectionStates>(
                        builder: (context, _) {
                          final show = context.read<ConnectionCubit>().showActions;
                          return IgnorePointer(
                            ignoring: !show,
                            child: AnimatedScale(
                              scale: show ? 1 : 0,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutBack,
                              child: AnimatedOpacity(
                                opacity: show ? 1 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: _TimerControlButton(
                                  isPaused: cubit.isPaused,
                                  onTap: cubit.toggleTimerPause,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Draws the main card's timer as a rounded-rect progress ring: a faint full
/// track plus a gradient stroke (side colours) that fills from the top-centre
/// clockwise as the speech elapses (§11).
class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0..1
  final Gradient gradient;
  final Color trackColor;
  final double radius;
  final double stroke;

  _ProgressRingPainter({
    required this.progress,
    required this.gradient,
    required this.trackColor,
    required this.radius,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = stroke / 2;
    final rect = Rect.fromLTWH(inset, inset, size.width - stroke, size.height - stroke);
    final r = radius - inset;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress <= 0) return;

    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + r), radius: Radius.circular(r))
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(Offset(rect.right - r, rect.bottom), radius: Radius.circular(r))
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - r), radius: Radius.circular(r))
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(Offset(rect.left + r, rect.top), radius: Radius.circular(r))
      ..lineTo(rect.center.dx, rect.top);

    final fg = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final metric = path.computeMetrics().first;
    canvas.drawPath(metric.extractPath(0, metric.length * progress), fg);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.gradient != gradient;
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RoleChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _IdleCard extends StatelessWidget {
  final String message;
  const _IdleCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DebateTheme.floatingCard(context),
        borderRadius: BorderRadius.circular(widgetBorderRadius + 4),
        border: Border.all(color: DebateTheme.textSecondary(context).withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline_rounded,
              size: 48, color: DebateTheme.textSecondary(context)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: DebateTheme.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// C3: the intro main card — the chair (welcome) with an "Introductions" chip and
/// NO timer, shown after the chair starts the live session and before P1.
class _IntroCard extends StatelessWidget {
  final String hostId;
  final String hostName;
  final String label;
  const _IntroCard({
    required this.hostId,
    required this.hostName,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebateController>();
    const cardRadius = widgetBorderRadius + 4;
    final hasHost = hostId.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: JadalColors.judgesGrey.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: JadalVideoCard(
                  name: hostName.isNotEmpty ? hostName : '—',
                  participantId: hasHost ? hostId : 'chair',
                  bgColor: DebateTheme.floatingCard(context),
                  showVideo: hasHost && cubit.showVideoForUser(hostId),
                  videoTrack: hasHost ? cubit.videoTrackForUser(hostId) : null,
                  isMicEnabled: hasHost && cubit.micOnForUser(hostId),
                  isSpeaking: hasHost && cubit.speakingForUser(hostId),
                  mainAxis: constraints.maxHeight,
                  borderRadius: cardRadius,
                ),
              ),
            ),
            PositionedDirectional(
              top: 12,
              start: 0,
              end: 0,
              child: Center(child: _RoleChip(label: label, color: JadalColors.judgesGrey)),
            ),
          ],
        );
      },
    );
  }
}

/// C1 / Update 1: the chair's circular, icon-only stop/resume timer button. Its
/// border is the card surface colour so it reads as straddling the card edge.
class _TimerControlButton extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onTap;
  const _TimerControlButton({required this.isPaused, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [JadalColors.primaryBlue, JadalColors.primaryOrange],
          ),
          border: Border.all(color: DebateTheme.background(context), width: 3),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 8),
          ],
        ),
        child: Icon(
          isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
