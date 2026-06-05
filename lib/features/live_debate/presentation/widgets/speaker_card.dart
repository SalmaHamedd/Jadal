import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../data/models/debate_models.dart';
import '../cubits/debate_cubit.dart';
import '../utils/avatar_palette.dart';
import '../utils/debate_theme.dart';
import 'poi_widgets.dart';

/// One debater card in the speakers section (§8.3 C). Role header on top, an
/// avatar/initial body (camera-off floating look) and overflow-safe name. A POI
/// bubble appears on the correct side when this debater raises a POI.
class SpeakerCard extends StatelessWidget {
  final Debater debater;
  final DebateSide side;
  final String roleLabel;
  final bool isCurrentSpeaker;
  final bool isAskingPoi;

  /// Whether the viewer can open the moderation dialog on tap (viewers/
  /// audience only — §8.3 C).
  final bool canModerate;

  /// Tapping the POI bubble (only meaningful for the current main speaker).
  final VoidCallback? onPoiTap;

  const SpeakerCard({
    super.key,
    required this.debater,
    required this.side,
    required this.roleLabel,
    required this.isCurrentSpeaker,
    required this.isAskingPoi,
    required this.canModerate,
    this.onPoiTap,
  });

  @override
  Widget build(BuildContext context) {
    final sideColor = DebateTheme.sideColor(side);
    final dark = DebateTheme.isDark(context);
    final pointsStart = side == DebateSide.proposition;

    return GestureDetector(
      onTap: canModerate
          ? () => showDialog(
                context: context,
                builder: (_) => SpeakerActionDialog(debater: debater, side: side),
              )
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: DebateTheme.floatingCard(context),
              borderRadius: BorderRadius.circular(widgetBorderRadius),
              border: Border.all(
                color: isCurrentSpeaker
                    ? sideColor
                    : sideColor.withValues(alpha: dark ? 0.40 : 0.65),
                width: isCurrentSpeaker ? 3 : 1.6,
              ),
              boxShadow: isCurrentSpeaker
                  ? [BoxShadow(color: sideColor.withValues(alpha: 0.35), blurRadius: 12)]
                  : null,
            ),
            child: Column(
              children: [
                // Role header.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: sideColor.withValues(alpha: isCurrentSpeaker ? 1 : 0.85),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(widgetBorderRadius - 2),
                    ),
                  ),
                  child: Text(
                    roleLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                // Avatar body + name.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, c) {
                                final d = c.biggest.shortestSide.clamp(28.0, 64.0);
                                return Container(
                                  width: d,
                                  height: d,
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
                                      fontSize: d * 0.42,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          debater.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: DebateTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // POI bubble (correct side, leaning toward the floor).
          if (isAskingPoi)
            PositionedDirectional(
              top: -10,
              start: pointsStart ? null : -6,
              end: pointsStart ? -6 : null,
              child: PoiBubble(
                pointsStart: pointsStart,
                color: DebateTheme.sideColor(side),
                size: 48,
                onTap: onPoiTap, // only the main speaker passes a handler
                onRefuse: () =>
                    context.read<DebateCubit>().refusePOI(debater.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tap dialog (viewers/audience only) showing the debater, their team for this
/// debate, and moderation actions (§8.3 C).
class SpeakerActionDialog extends StatelessWidget {
  final Debater debater;
  final DebateSide side;
  const SpeakerActionDialog({super.key, required this.debater, required this.side});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateCubit>();
    final team = cubit.teamFor(side);
    final sideColor = DebateTheme.sideColor(side);

    return AlertDialog(
      backgroundColor: DebateTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: avatarColorFor(debater.id),
            child: Text(
              avatarInitial(debater.name),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            debater.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: DebateTheme.textPrimary(context),
            ),
          ),
          Text(
            team.teamName,
            style: TextStyle(fontFamily: 'Cairo', color: sideColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          // TODO(role-gating): force-mute / force-camera are judge actions.
          _ActionTile(
            icon: Icons.mic_off_rounded,
            label: loc.forceMute,
            onTap: () {
              cubit.forceMute(debater.id);
              Navigator.of(context).maybePop();
            },
          ),
          _ActionTile(
            icon: Icons.videocam_off_rounded,
            label: loc.forceCameraOff,
            onTap: () {
              cubit.forceCameraOff(debater.id);
              Navigator.of(context).maybePop();
            },
          ),
          _ActionTile(
            icon: Icons.person_rounded,
            label: loc.goToProfile,
            onTap: () => _confirmLeaveForProfile(context, cubit),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(loc.cancel),
        ),
      ],
    );
  }

  Future<void> _confirmLeaveForProfile(BuildContext context, DebateCubit cubit) async {
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DebateTheme.surface(context),
        title: Text(loc.areYouSure, style: const TextStyle(fontFamily: 'Cairo')),
        content: Text(loc.leaveToProfileWarning, style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.disconnect();
      if (context.mounted) {
        Navigator.of(context)
          ..maybePop()
          ..maybePop();
      }
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: DebateTheme.textPrimary(context)),
      title: Text(
        label,
        style: TextStyle(fontFamily: 'Cairo', color: DebateTheme.textPrimary(context)),
      ),
      onTap: onTap,
    );
  }
}
