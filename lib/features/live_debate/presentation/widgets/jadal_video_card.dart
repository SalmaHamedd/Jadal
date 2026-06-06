import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/constants/constants.dart';
import '../utils/avatar_palette.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final scale = (mainAxis / 168).clamp(0.5, 2.2);
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
          PositionedDirectional(
            bottom: 6 * scale,
            start: 8 * scale,
            end: 8 * scale,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: live ? Colors.white : (nameColor ?? Colors.white),
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                fontSize: 12 * scale,
                shadows: live
                    ? const [Shadow(color: Colors.black54, blurRadius: 4)]
                    : null,
              ),
            ),
          ),
          // Mic / speaking badge.
          PositionedDirectional(
            top: 6 * scale,
            end: 6 * scale,
            child: isMicEnabled
                ? SpeakingIndicator(isSpeaking: isSpeaking, scale: scale)
                : MuteIndicator(scale: scale),
          ),
        ],
      ),
    );
  }
}
