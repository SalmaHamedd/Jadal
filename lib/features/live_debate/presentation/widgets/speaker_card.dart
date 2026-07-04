import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../data/models/debate_models.dart';
import '../utils/avatar_palette.dart';
import '../utils/debate_theme.dart';
import 'call_indicators.dart';

/// One debater card in the speakers section (§8.3 C). Role header on top, then a
/// body that reflects **real presence**: the debater's camera (if on), their
/// avatar (camera off but present), or a "hasn't joined yet" fallback when the
/// assigned user isn't actually in the room. A POI bubble appears on the correct
/// side when this debater raises a POI.
///
/// Presentational only — selection (the bottom-end 3-dots) + the details dialog
/// are handled by the surrounding [SelectableCard] (§9.2).
class SpeakerCard extends StatelessWidget {
  final Debater debater;
  final DebateSide side;
  final String roleLabel;
  final bool isCurrentSpeaker;
  final bool isAskingPoi;

  /// Whether the assigned debater is actually connected to the room. When false
  /// the card renders the "hasn't joined yet" fallback instead of an avatar.
  final bool isPresent;

  /// Whether to render [videoTrack] (camera on for a present debater).
  final bool showVideo;
  final VideoTrack? videoTrack;

  /// Mic state for the small in-card speaking/mute badge (present debaters only).
  final bool micOn;
  final bool isSpeaking;

  /// Live 0..1 level for the badge's meter (local user only; null otherwise).
  final double Function()? levelProvider;

  /// Tapping the POI bubble (only meaningful for the current main speaker).
  final VoidCallback? onPoiTap;

  const SpeakerCard({
    super.key,
    required this.debater,
    required this.side,
    required this.roleLabel,
    required this.isCurrentSpeaker,
    required this.isAskingPoi,
    this.isPresent = true,
    this.showVideo = false,
    this.videoTrack,
    this.micOn = false,
    this.isSpeaking = false,
    this.levelProvider,
    this.onPoiTap,
  });

  @override
  Widget build(BuildContext context) {
    final sideColor = DebateTheme.sideColor(side);
    final dark = DebateTheme.isDark(context);
    final pointsStart = side == DebateSide.proposition;

    // Avatar size is derived from screen width (not the card's available height)
    // so it stays fixed when the toolbar shows/hides (§U4b).
    final w = MediaQuery.of(context).size.width;
    final avatarD = (w * 0.085).clamp(22.0, 40.0).toDouble();

    final borderWidth = isCurrentSpeaker ? 3.0 : 1.6;
    // Inner radius = outer − border so no background sliver shows at the corners.
    final innerR = (widgetBorderRadius - borderWidth).clamp(0.0, widgetBorderRadius);

    // Absent debaters read as a quiet, dashed-feeling placeholder: muted side
    // colour, no glow, lower-contrast body.
    final borderColor = !isPresent
        ? DebateTheme.textSecondary(context).withValues(alpha: dark ? 0.35 : 0.45)
        : isCurrentSpeaker
            ? sideColor
            : sideColor.withValues(alpha: dark ? 0.40 : 0.65);
    final live = isPresent && showVideo && videoTrack != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: DebateTheme.floatingCard(context),
            borderRadius: BorderRadius.circular(widgetBorderRadius),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: (isCurrentSpeaker && isPresent)
                ? [BoxShadow(color: sideColor.withValues(alpha: 0.35), blurRadius: 12)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(innerR),
            child: Column(
              children: [
                // Role header (corners rounded by the clip above). Dimmed when
                // the slot's debater hasn't joined.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: !isPresent
                      ? DebateTheme.textSecondary(context).withValues(alpha: 0.55)
                      : sideColor.withValues(alpha: isCurrentSpeaker ? 1 : 0.85),
                  child: Text(
                    roleLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  child: !isPresent
                      ? _NotJoinedBody(name: debater.name)
                      : Stack(
                          children: [
                            if (live)
                              Positioned.fill(child: VideoTrackRenderer(videoTrack!))
                            else
                              Center(
                                child: Container(
                                  width: avatarD,
                                  height: avatarD,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: avatarColorFor(debater.id),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    avatarInitial(debater.name),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w800,
                                      fontSize: avatarD * 0.42,
                                    ),
                                  ),
                                ),
                              ),
                            // Small speaking / mute badge — sized down so it fits
                            // the little card (§UX). Muted → red mic-off; talking →
                            // animated bars in the side colour.
                            PositionedDirectional(
                              top: 4,
                              end: 4,
                              child: MicVolumeIndicator(
                                micOn: micOn,
                                isSpeaking: isSpeaking,
                                scale: 0.62,
                                activeColor: sideColor,
                                levelProvider: levelProvider,
                              ),
                            ),
                            PositionedDirectional(
                              bottom: 6,
                              start: 8,
                              end: 28, // leave room for the bottom-end 3-dots
                              child: Text(
                                debater.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: live
                                      ? Colors.white
                                      : DebateTheme.textPrimary(context),
                                  shadows: live
                                      ? const [Shadow(color: Colors.black54, blurRadius: 4)]
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        // POI indicator — a small raised-hand badge (matches the central POI
        // channel). Only a present debater can be raising one; tapping it lets the
        // current main speaker accept/refuse.
        if (isAskingPoi && isPresent)
          PositionedDirectional(
            top: -8,
            start: pointsStart ? null : -4,
            end: pointsStart ? -4 : null,
            child: GestureDetector(
              onTap: onPoiTap,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sideColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: sideColor.withValues(alpha: 0.5), blurRadius: 8)],
                ),
                child: const Icon(Icons.front_hand_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}

/// Body shown when the slot's assigned debater hasn't connected yet (§ presence).
class _NotJoinedBody extends StatelessWidget {
  final String name;
  const _NotJoinedBody({required this.name});

  @override
  Widget build(BuildContext context) {
    final muted = DebateTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, color: muted.withValues(alpha: 0.7), size: 26),
          const SizedBox(height: 6),
          Text(
            context.loc.notJoinedYet,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w500,
              fontSize: 10,
              color: muted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
