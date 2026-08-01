import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_cubit/app_cubit.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';

/// The 3-dots settings menu (§8.5): mute-all, open-lobby toggle, team chat,
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
                // toggles to "unmute all" while active (§U4b).
                if (cubit.canModerateOthers)
                  _Item(
                    icon: cubit.muteAllActive ? Icons.mic_rounded : Icons.mic_off_rounded,
                    label: cubit.muteAllActive ? loc.unmuteAll : loc.muteAll,
                    onTap: () {
                      cubit.toggleMuteAll();
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
                // Chair-only: room-wide camera lock (mirrors mute-all, §FE-6).
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
                // Chair-only: open-lobby / stage control (§8). Hidden once the
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
                // FE-6: chair shares the STORED result from the LIVE room (not the
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
                // Chair-only: close the room — kicks everyone to the rooms list (§U4b).
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
                  onTap: () => _confirmLeave(context, sheetCtx, cubit),
                ),
                const Divider(height: 24),
                // Test-only theme toggle (no AppBar to hold it — §8.5).
                _Item(
                  icon: Icons.brightness_6_rounded,
                  label: loc.themeToggleTest,
                  onTap: () {
                    context
                        .read<AppCubit>()
                        .toggleTheme(MediaQuery.platformBrightnessOf(context));
                    Navigator.of(sheetCtx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _confirmLeave(
      BuildContext context, BuildContext sheetCtx, DebateController cubit) async {
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: sheetCtx,
      builder: (_) => AlertDialog(
        backgroundColor: DebateTheme.surface(context),
        title: Text(loc.areYouSure, style: AppTextStyles.title(context)),
        content: Text(loc.leaveDebateBody, style: AppTextStyles.body(context)),
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
      if (!context.mounted) return;
      // Leave → back to the debate DETAILS screen, not the rooms list (§UX). The
      // stack is Details → RoomsList(lobby) → Room, so we pop the settings sheet,
      // then the room (its disconnect-listener is now gone, so it can't pop again),
      // disconnect while the lobby still owns the cubit, then pop the rooms list.
      final nav = Navigator.of(context);
      if (sheetCtx.mounted) Navigator.of(sheetCtx).pop(); // close settings sheet
      nav.pop(); // room → rooms list
      await cubit.disconnect();
      if (nav.mounted && nav.canPop()) nav.pop(); // rooms list → details
    }
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
