import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../utils/avatar_palette.dart';
import '../utils/debate_theme.dart';
import 'call_indicators.dart';

/// Reusable participant tile (camera stream or deterministic-colour avatar),
/// recolored from the legacy `VideoCard` (§8.2/§8.3 C). Used by both the grid
/// layout and the speaker cards.
class JadalVideoCard extends StatelessWidget {
  final String name;
  final String participantId;
  final Color bgColor;
  final bool showVideo;
  final VideoTrack? videoTrack;
  final bool isMicEnabled;
  final bool isSpeaking;

  /// The card's short side, drives proportional sizing.
  final double mainAxis;
  final double? borderRadius;
  final Color? nameColor;

  /// Live 0..1 audio level for the volume meter (null → no meter source).
  final double Function()? micLevel;

  /// Bars colour for the volume meter when the mic is on.
  final Color? micActiveColor;

  /// Width of an obstruction centred on the card's bottom edge (the chair's
  /// stop/resume timer button). The name row keeps clear of it.
  final double bottomCenterReserved;

  const JadalVideoCard({
    super.key,
    required this.name,
    required this.participantId,
    required this.bgColor,
    required this.showVideo,
    required this.videoTrack,
    required this.isMicEnabled,
    required this.isSpeaking,
    required this.mainAxis,
    this.borderRadius,
    this.nameColor,
    this.micLevel,
    this.micActiveColor,
    this.bottomCenterReserved = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _build(context, constraints.maxWidth),
    );
  }

  Widget _build(BuildContext context, double cardWidth) {
    final scale = (mainAxis / 168).clamp(0.5, 2.2);
    // The mic badge was reading too small on the big main card, so nudge the cap
    // up (and the floor up for the small grid tiles) — clearly visible on the
    // main speaker card, but still balanced so it never balloons.
    final micScale = scale.clamp(0.78, 1.65).toDouble();
    final live = showVideo && videoTrack != null;
    final radius = borderRadius ?? widgetBorderRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          Positioned.fill(
            child: Container(
              color: bgColor,
              child: live
                  ? VideoTrackRenderer(
                      videoTrack!,
                      // fit: VideoViewFit.cover,
                    )
                  : Center(
                      child: Container(
                        width: 46 * scale,
                        height: 46 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: avatarColorFor(participantId),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          avatarInitial(name),
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontSize: 22 * scale,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          // Name (overflow-safe).
          //
          // On the main speaker card the chair's stop/resume button straddles
          // the bottom edge, centred — it used to sit right on top of the name.
          // [bottomCenterReserved] pulls the name's trailing edge back to just
          // before the button, so it shrinks/ellipsises into the free space
          // instead of running underneath it.
          PositionedDirectional(
            bottom: 6 * scale,
            start: 8 * scale,
            end: bottomCenterReserved > 0
                ? (cardWidth / 2) + (bottomCenterReserved / 2) + 6
                : 8 * scale,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // Over a video the name sits on dark footage → white. On the
                // avatar/card surface it must follow the theme (dark in light
                // theme) like the team cards, not be hard-coded white.
                color: live
                    ? Colors.white
                    : (nameColor ?? DebateTheme.textPrimary(context)),
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                fontSize: 13 * scale,
                shadows: live
                    ? const [Shadow(color: Colors.black54, blurRadius: 4)]
                    : null,
              ),
            ),
          ),
          // Mic / volume badge (fixed footprint → never shifts on toggle).
          PositionedDirectional(
            top: 6 * micScale,
            end: 6 * micScale,
            child: MicVolumeIndicator(
              micOn: isMicEnabled,
              isSpeaking: isSpeaking,
              scale: micScale,
              activeColor: micActiveColor ?? JadalColors.primaryBlue,
              levelProvider: micLevel,
            ),
          ),
        ],
      ),
    );
  }
}
