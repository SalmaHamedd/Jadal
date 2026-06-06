import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_dialog.dart';
import '../cubits/debate_cubit.dart';
import '../utils/debate_theme.dart';

/// Team-only chat (§8.5): send/receive messages over the `team_chat` socket
/// event; messages render only for same-team participants (filtered by
/// [teamId]). Overflow-safe bubbles.
class TeamChatDialog extends StatefulWidget {
  final String teamId;
  const TeamChatDialog({super.key, required this.teamId});

  @override
  State<TeamChatDialog> createState() => _TeamChatDialogState();
}

class _TeamChatDialogState extends State<TeamChatDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(DebateCubit cubit) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    cubit.sendTeamChat(teamId: widget.teamId, message: text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final size = MediaQuery.of(context).size;
    return JadalDialog(
      width: size.width * 0.9,
      height: size.height * 0.7,
      firstColor: JadalColors.primaryBlue,
      secondColor: JadalColors.primaryOrange,
      bodyColor: DebateTheme.surface(context),
      title: loc.teamChat,
      body: BlocBuilder<DebateCubit, DebateStates>(
        builder: (context, state) {
          final cubit = context.read<DebateCubit>();
          final localId = cubit.localParticipant?.identity ?? cubit.data.currentUserId;
          final messages = cubit.chatFor(widget.teamId);
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          loc.noMessages,
                          style: TextStyle(
                              fontFamily: 'Cairo', color: DebateTheme.textSecondary(context)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final mine = m.senderId == localId;
                          return Align(
                            alignment:
                                mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(maxWidth: size.width * 0.6),
                              decoration: BoxDecoration(
                                color: mine
                                    ? JadalColors.primaryBlue
                                    : DebateTheme.surfaceElevated(context),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.senderName,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: mine
                                          ? Colors.white70
                                          : DebateTheme.textSecondary(context),
                                    ),
                                  ),
                                  Text(
                                    m.message,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: mine ? Colors.white : DebateTheme.textPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(cubit),
                        style: TextStyle(
                            fontFamily: 'Cairo', color: DebateTheme.textPrimary(context)),
                        decoration: InputDecoration(
                          hintText: loc.messageHint,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _send(cubit),
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(backgroundColor: JadalColors.primaryBlue),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
