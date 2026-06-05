import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../cubits/debate_cubit.dart';
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
    return BlocBuilder<DebateCubit, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateCubit>();
        final dark = DebateTheme.isDark(context);
        final slot = cubit.currentSlot;

        if (slot == null) {
          return _IdleCard(message: loc.tapNextToStart);
        }

        final side = slot.side;
        final tier = cubit.currentTier;
        final accent = DebateTheme.tierAccent(tier, side, dark);
        final gradient = DebateTheme.sideGradient(side, dark);
        final speaker = cubit.debaterAt(side, slot.orderIndex);

        return LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            return Stack(
              children: [
                // Gradient border frame.
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widgetBorderRadius + 4),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: JadalVideoCard(
                      name: speaker.name,
                      participantId: speaker.id,
                      bgColor: DebateTheme.floatingCard(context),
                      showVideo: cubit.isCameraEnabled,
                      videoTrack: cubit.localVideoTrack,
                      isMicEnabled: cubit.isMicEnabled,
                      isSpeaking: cubit.isLocalSpeaking,
                      mainAxis: h,
                      borderRadius: widgetBorderRadius,
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
                // Timer (top-start).
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: DebateTimerBadge(
                    elapsedSeconds: cubit.elapsedSeconds,
                    timeline: cubit.timeline,
                    side: side,
                  ),
                ),
                // Tier / POI treatment (bottom-start).
                PositionedDirectional(
                  bottom: 12,
                  start: 12,
                  child: _TierPill(tier: tier, accent: accent),
                ),
              ],
            );
          },
        );
      },
    );
  }
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

class _TierPill extends StatelessWidget {
  final DebateTier tier;
  final Color accent;
  const _TierPill({required this.tier, required this.accent});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final (IconData icon, String text) = switch (tier) {
      DebateTier.protected => (Icons.lock_rounded, loc.protected),
      DebateTier.open => (Icons.lock_open_rounded, loc.open),
      DebateTier.extra => (Icons.timelapse_rounded, loc.extraTime),
      DebateTier.timeOff => (Icons.block_rounded, loc.time_over),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
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
