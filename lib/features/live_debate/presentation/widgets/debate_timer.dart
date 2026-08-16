import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../data/models/debate_models.dart';
import '../utils/debate_theme.dart';
import '../utils/debate_timeline.dart';

/// Timer chip attached to the main speaker card. Generalized from the legacy
/// `ScalableDebateTimer`: all thresholds come from [timeline], and the
/// colour follows the current [DebateTier] (protected/open/extra/timeOff).
class DebateTimerBadge extends StatelessWidget {
  final int elapsedSeconds;
  final DebateTimeline timeline;
  final DebateSide side;
  final bool isReply;
  final double width;
  final double height;

  const DebateTimerBadge({
    super.key,
    required this.elapsedSeconds,
    required this.timeline,
    required this.side,
    this.isReply = false,
    this.width = 110,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final dark = DebateTheme.isDark(context);
    final tier = timeline.tierAt(elapsedSeconds, isReply: isReply);
    final accent = DebateTheme.tierAccent(tier, side, dark);

    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');

    // Reply speeches have no POIs, so never show the "POIs open" wording.
    final label = switch (tier) {
      DebateTier.protected => loc.protected,
      DebateTier.open => isReply ? loc.speaking : loc.open,
      DebateTier.extra => loc.extraTime,
      DebateTier.timeOff => loc.time_over,
    };

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DebateTheme.surface(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
    );
  }
}
