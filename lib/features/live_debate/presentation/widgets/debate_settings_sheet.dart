import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_cubit/app_cubit.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubits/debate_cubit.dart';
import '../utils/debate_theme.dart';
import 'team_chat_dialog.dart';

/// The 3-dots settings menu (§8.5): mute-all, open-lobby toggle, team chat,
/// leave-with-confirm and the (test-only) theme toggle.
class DebateSettingsSheet {
  DebateSettingsSheet._();

  static Future<void> show(BuildContext context, DebateCubit cubit) {
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
                // TODO(role-gating): judge-only.
                _Item(
                  icon: Icons.mic_off_rounded,
                  label: loc.muteAll,
                  onTap: () {
                    cubit.muteAll();
                    Navigator.of(sheetCtx).pop();
                  },
                ),
                // TODO(role-gating): judge-only.
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
                _Item(
                  icon: Icons.chat_rounded,
                  label: loc.teamChat,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        // TODO(role-gating): viewer's real team id.
                        child: TeamChatDialog(teamId: cubit.data.propositionTeam.teamId),
                      ),
                    );
                  },
                ),
                _Item(
                  icon: Icons.logout_rounded,
                  label: loc.leaveDebate,
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
      BuildContext context, BuildContext sheetCtx, DebateCubit cubit) async {
    final loc = context.loc;
    final confirmed = await showDialog<bool>(
      context: sheetCtx,
      builder: (_) => AlertDialog(
        backgroundColor: DebateTheme.surface(context),
        title: Text(loc.areYouSure, style: const TextStyle(fontFamily: 'Cairo')),
        content: Text(loc.leaveDebateBody, style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(sheetCtx).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(sheetCtx).pop(true),
            child: Text(loc.confirm, style: const TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.disconnect();
      if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
      if (context.mounted) Navigator.of(context).maybePop();
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
        style: TextStyle(fontFamily: 'Cairo', color: color, fontWeight: FontWeight.w600),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
