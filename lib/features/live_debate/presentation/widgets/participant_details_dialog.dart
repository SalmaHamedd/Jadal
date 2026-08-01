import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/debate_models.dart';
import '../cubits/connection_cubit.dart';
import '../cubits/debate_controller.dart';
import '../utils/avatar_palette.dart';
import '../utils/debate_theme.dart';

/// Which corner the selection 3-dots button sits in.
enum CardDotsCorner { topStart, bottomEnd }

/// Wraps a participant card so a tap **selects** it — revealing a 3-dots button
/// (and the action row, via [ConnectionCubit]) — and the 3-dots opens the
/// participant-details dialog (§9.2/§9.3). Requires a [ConnectionCubit] above.
///
/// The dots are padded off the card edge and placed at [dotsCorner] so they
/// never sit on the border or overlap the mic badge (§U4a/§U4b).
class SelectableCard extends StatelessWidget {
  final String participantId;
  final Widget child;
  final VoidCallback onShowDetails;
  final CardDotsCorner dotsCorner;

  const SelectableCard({
    super.key,
    required this.participantId,
    required this.child,
    required this.onShowDetails,
    this.dotsCorner = CardDotsCorner.topStart,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionCubit, ConnectionStates>(
      builder: (context, _) {
        final connection = context.read<ConnectionCubit>();
        final selected = connection.selectedParticipantId == participantId;
        final topStart = dotsCorner == CardDotsCorner.topStart;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => connection.selectParticipant(participantId),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (selected)
                PositionedDirectional(
                  top: topStart ? 6 : null,
                  bottom: topStart ? null : 6,
                  start: topStart ? 6 : null,
                  end: topStart ? null : 6,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onShowDetails,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Shows the participant-details dialog with the [DebateController] provided to
/// the dialog's subtree (fixes the old `context.read` crash — the dialog runs in
/// a fresh route without the provider unless we pass it through, §9.2).
void showParticipantDetails(
  BuildContext context,
  DebateController controller, {
  required String participantId,
  required String name,
}) {
  showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: controller,
      child: ParticipantDetailsDialog(participantId: participantId, name: name),
    ),
  );
}

/// Participant-details dialog (§9.2): avatar, name, team, and the
/// **role-appropriate** actions — force-mute / force-camera-off only for the
/// chair ([DebateController.canModerateOthers]); go-to-profile for everyone.
class ParticipantDetailsDialog extends StatelessWidget {
  final String participantId;
  final String name;

  const ParticipantDetailsDialog({
    super.key,
    required this.participantId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateController>();

    TeamInfo? team;
    DebateSide? side;
    for (final s in DebateSide.values) {
      final t = cubit.teamFor(s);
      if (t.debaterById(participantId) != null) {
        team = t;
        side = s;
        break;
      }
    }
    final accent = side != null ? DebateTheme.sideColor(side) : JadalColors.judgesGrey;
    final subtitle = team?.teamName ?? '';
    final dark = DebateTheme.isDark(context);
    final micLocked = cubit.publishLockedIds.contains(participantId);
    final cameraLocked = cubit.cameraLockedIds.contains(participantId);

    return Dialog(
      backgroundColor: DebateTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Soft accent header in the participant's side colour — fades into the
          // body so it frames the avatar without a hard coloured band (§dialogs).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: dark ? 0.40 : 0.20),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: avatarColorFor(participantId),
                  child: Text(
                    avatarInitial(name),
                    style: AppTextStyles.displayTitle(context).copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title(context)
                      .copyWith(color: DebateTheme.textPrimary(context)),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subtitle,
                      style: AppTextStyles.caption(context)
                          .copyWith(color: accent, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Moderation actions — chair only (§8).
                if (cubit.canModerateOthers) ...[
                  // Per-user publish lock: prevents this user from re-opening their
                  // mic (not just a one-off mute); toggles to unblock (§U4b).
                  _ActionTile(
                    icon: micLocked ? Icons.mic_rounded : Icons.mic_off_rounded,
                    label: micLocked ? loc.unmuteUser : loc.muteUser,
                    onTap: () {
                      cubit.toggleUserPublishLock(participantId);
                      Navigator.of(context).maybePop();
                    },
                  ),
                  // Per-user camera lock — same model, so the user can't re-open
                  // their camera until the chair allows it again (§FE-6).
                  _ActionTile(
                    icon: cameraLocked
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: cameraLocked ? loc.allowCamera : loc.forceCameraOff,
                    onTap: () {
                      cubit.toggleUserCameraLock(participantId);
                      Navigator.of(context).maybePop();
                    },
                  ),
                ],
                _ActionTile(
                  icon: Icons.person_rounded,
                  label: loc.goToProfile,
                  onTap: () => _confirmLeaveForProfile(context, cubit),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(loc.cancel),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeaveForProfile(BuildContext context, DebateController cubit) async {
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DebateTheme.surface(context),
        title: Text(loc.areYouSure, style: AppTextStyles.title(context)),
        content: Text(loc.leaveToProfileWarning, style: AppTextStyles.body(context)),
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
        style: AppTextStyles.body(context).copyWith(color: DebateTheme.textPrimary(context)),
      ),
      onTap: onTap,
    );
  }
}
