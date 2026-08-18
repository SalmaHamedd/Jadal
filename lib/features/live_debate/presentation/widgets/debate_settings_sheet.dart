import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../cubits/connection_cubit.dart';
import '../cubits/debate_controller.dart';
import '../pages/result_room_screen.dart';
import '../utils/debate_theme.dart';

/// The 3-dots settings menu: mute-all, open-lobby toggle, team chat,
/// leave-with-confirm and the (test-only) theme toggle.
class DebateSettingsSheet {
  DebateSettingsSheet._();

  static Future<void> show(BuildContext context, DebateController cubit) {
    final loc = context.loc;
    return showModalBottomSheet(
      context: context,
      backgroundColor: DebateTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: DebateTheme.textSecondary(sheetCtx).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Chair-only: room-wide publish lock (prevents opening mics);
                // toggles to "unmute all" while active.
                if (cubit.canModerateOthers)
                  _Item(
                    icon: cubit.muteAllActive ? Icons.mic_rounded : Icons.mic_off_rounded,
                    label: cubit.muteAllActive ? loc.unmuteAll : loc.muteAll,
                    onTap: () {
                      cubit.toggleMuteAll();
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
                // Chair-only: room-wide camera lock (mirrors mute-all).
                if (cubit.canModerateOthers)
                  _Item(
                    icon: cubit.cameraAllOff
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: cubit.cameraAllOff ? loc.allowCameraAll : loc.cameraOffAll,
                    onTap: () {
                      cubit.toggleCameraAll();
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
                // Chair-only: open-lobby / stage control. Hidden once the
                // speeches are done (result phase / waiting / shared result) — the
                // room stays in the open lobby then, so the toggle is meaningless.
                if (cubit.canControlStage && !cubit.resultPhaseOpen)
                  _Item(
                    icon: cubit.isLobbyMode ? Icons.grid_view_rounded : Icons.grid_on_rounded,
                    label: loc.openLobbyMode,
                    trailing: Switch(
                      value: cubit.isLobbyMode,
                      onChanged: (v) {
                        cubit.setLobbyMode(v);
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                    onTap: () {
                      cubit.setLobbyMode(!cubit.isLobbyMode);
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
                // The result screen is pushed automatically when the chair
                // shares, but backing out of it used to be final. This is the
                // way back for anyone who has a result to look at.
                if (cubit.resultView != null)
                  _Item(
                    icon: Icons.emoji_events_outlined,
                    label: loc.viewResult,
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      _openResult(context, cubit);
                    },
                  ),
                // Chair shares the STORED result from the LIVE room (not the
                // result room) — enabled once a result exists and until it's
                // revealed; everyone is taken to the result screen with confetti.
                if (cubit.canManageResult &&
                    cubit.hasResult &&
                    !(cubit.resultView?.revealed ?? false))
                  _Item(
                    icon: Icons.emoji_events_rounded,
                    label: loc.shareResult,
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      cubit.shareResult();
                    },
                  ),
                // Copies the debate's public link so anyone can watch as a
                // guest. The backend withholds the link from guests, so they
                // can never pass it on.
                if (!cubit.isGuest && (cubit.shareUrl?.isNotEmpty ?? false))
                  _Item(
                    icon: Icons.share_rounded,
                    label: loc.shareDebate,
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      _copyShareLink(context, cubit.shareUrl!);
                    },
                  ),
                // Chair-only: close the room and send everyone back to the list.
                if (cubit.canControlStage)
                  _Item(
                    icon: Icons.meeting_room_rounded,
                    label: loc.closeRoom,
                    danger: true,
                    onTap: () => _confirmCloseRoom(context, sheetCtx, cubit),
                  ),
                _Item(
                  icon: Icons.logout_rounded,
                  label: loc.leaveSession,
                  danger: true,
                  onTap: () {
                    // Close the sheet first, then run the shared confirm/leave
                    // flow on the room's own context.
                    Navigator.of(sheetCtx).pop();
                    confirmAndLeave(context, cubit);
                  },
                ),
                // Theme switching lives in the nav drawer, not here — it has no
                // business being a one-tap action mid-debate.
              ],
            ),
          ),
        );
      },
    );
  }

  /// Re-opens the result on top of the room. Pushed, never navigated to, so the
  /// LiveKit connection survives and backing out returns to the debate.
  static void _openResult(BuildContext context, DebateController cubit) {
    final connection = context.read<ConnectionCubit>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: connection),
        ],
        child: const ResultRoomScreen(),
      ),
    ));
  }

  /// Puts the debate's link on the clipboard and confirms it with a snackbar.
  static Future<void> _copyShareLink(BuildContext context, String url) async {
    final message = context.loc.debateLinkCopied;
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    JadalSnackBar.show(context, message, type: SnackBarType.success);
  }

  /// The single leave-session flow, used by both the sheet item and the system
  /// back button: confirm, tear the connection down silently, then navigate
  /// back through Room → RoomsList → Details.
  /// The disconnect is silent (no [DebateDisconnectedState]) so the room's
  /// pop-on-disconnect listener can't fire mid-animation and pop a route too
  /// many, which is what happened when this popped before disconnecting.
  static Future<void> confirmAndLeave(
      BuildContext context, DebateController cubit) async {
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: DebateTheme.surface(context),
        title: Text(loc.areYouSure, style: AppTextStyles.title(context)),
        content: Text(loc.leaveDebateBody, style: AppTextStyles.body(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(loc.confirm,
                style: AppTextStyles.button(context).copyWith(color: const Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final nav = Navigator.of(context);
    await cubit.disconnect(notify: false);
    if (!nav.mounted) return;
    nav.pop(); // room → rooms list
    // A guest came straight from a link, so the room is their only route —
    // popping again would take them out of a screen they never opened.
    if (!cubit.isGuest && nav.canPop()) nav.pop(); // rooms list → details
  }

  static Future<void> _confirmCloseRoom(
      BuildContext context, BuildContext sheetCtx, DebateController cubit) async {
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: sheetCtx,
      builder: (_) => AlertDialog(
        backgroundColor: DebateTheme.surface(context),
        title: Text(loc.areYouSure, style: AppTextStyles.title(context)),
        content: Text(loc.closeRoomBody, style: AppTextStyles.body(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(sheetCtx).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(sheetCtx).pop(true),
            child: Text(loc.confirm,
                style: AppTextStyles.button(context).copyWith(color: const Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
      // Everyone (incl. the chair) is taken back via the RoomClosedState listener.
      await cubit.closeRoom();
    }
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFE53935) : DebateTheme.textPrimary(context);
    return ListTile(
      leading: Icon(icon, color: danger ? color : JadalColors.primaryBlue),
      title: Text(
        label,
        style: AppTextStyles.body(context).copyWith(color: color, fontWeight: FontWeight.w600),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
