import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
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

  /// Live 0..1 audio level for the volume meter (null → no meter source).
  final double Function()? micLevel;

  /// Bars colour for the volume meter when the mic is on.
  final Color? micActiveColor;

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
  });

  @override
  Widget build(BuildContext context) {
    final scale = (mainAxis / 168).clamp(0.5, 2.2);
    // The mic badge shouldn't balloon on the big main card — cap it tighter.
    final micScale = scale.clamp(0.65, 1.0).toDouble();
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
