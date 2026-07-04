import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_dialog.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';

/// Team-only chat (§8.5): send/receive messages over the `team_chat` socket
/// event; messages render only for same-team participants (filtered by
/// [teamId]). Overflow-safe bubbles.
///
/// The chat is coloured by side — blue / deep-blue for the proposition team and
/// orange / dark-orange for the opposition — so each team's chat reads as its
/// own. It opens scrolled to the newest message (like a normal messenger) and,
/// when a message arrives while the user has scrolled up, shows a "new messages"
/// pill that jumps them back to the bottom.
class TeamChatDialog extends StatefulWidget {
  final String teamId;
  const TeamChatDialog({super.key, required this.teamId});

  @override
  State<TeamChatDialog> createState() => _TeamChatDialogState();
}

class _TeamChatDialogState extends State<TeamChatDialog> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _showJump = false;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    // Tell the cubit the chat is open so inbound messages stop counting as unread
    // (and clear the current dot).
    context.read<DebateController>().setTeamChatOpen(true);
    _scroll.addListener(_onScroll);
    // Land on the newest message on open.
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom(animated: false));
  }

  @override
  void dispose() {
    context.read<DebateController>().setTeamChatOpen(false);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _nearBottom {
    if (!_scroll.hasClients) return true;
    return (_scroll.position.maxScrollExtent - _scroll.position.pixels) < 80;
  }

  void _onScroll() {
    if (_showJump && _nearBottom) setState(() => _showJump = false);
  }

  void _jumpToBottom({bool animated = true}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (animated) {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(target);
    }
    if (_showJump) setState(() => _showJump = false);
  }

  void _send(DebateController cubit) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    cubit.sendTeamChat(teamId: widget.teamId, message: text);
    _controller.clear();
    // Sending always snaps to the bottom (own message).
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  /// A new message arrived: auto-follow if the user is already at the bottom,
  /// otherwise surface the "new messages" jump pill.
  void _onNewMessages() {
    if (_nearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    } else if (!_showJump) {
      setState(() => _showJump = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final size = MediaQuery.of(context).size;
    final cubit = context.read<DebateController>();
    // Side palette: proposition = blue / deep-blue, opposition = orange / dark-orange.
    final isProp = widget.teamId == cubit.data.propositionTeam.teamId;
    final primary = isProp ? JadalColors.primaryBlue : JadalColors.primaryOrange;
    final deep = isProp ? JadalColors.deepBlue : const Color(0xFF9C4E12);

    return JadalDialog(
      width: size.width * 0.9,
      height: size.height * 0.7,
      firstColor: primary,
      secondColor: deep,
      bodyColor: DebateTheme.surface(context),
      title: loc.teamChat,
      body: BlocConsumer<DebateController, DebateStates>(
        listenWhen: (_, s) => s is TeamChatUpdatedState,
        listener: (context, _) {
          final count = cubit.chatFor(widget.teamId).length;
          if (count > _lastCount) _onNewMessages();
          _lastCount = count;
        },
        builder: (context, state) {
          final localId = cubit.localParticipant?.identity ?? cubit.data.currentUserId;
          final messages = cubit.chatFor(widget.teamId);
          _lastCount = messages.length;
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
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(12),
                            itemCount: messages.length,
                            itemBuilder: (context, i) {
                              final m = messages[i];
                              final mine = m.senderId == localId;
                              // Received bubbles get a tinted fill + border so they
                              // read clearly against the near-white dialog (§11).
                              final receivedBg = DebateTheme.isDark(context)
                                  ? DebateTheme.surfaceElevated(context)
                                  : Color.lerp(
                                      JadalColors.lightSurface, primary, 0.07)!;
                              return Align(
                                alignment: mine
                                    ? AlignmentDirectional.centerEnd
                                    : AlignmentDirectional.centerStart,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  constraints: BoxConstraints(maxWidth: size.width * 0.6),
                                  decoration: BoxDecoration(
                                    color: mine ? primary : receivedBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: mine
                                        ? null
                                        : Border.all(
                                            color: primary.withValues(alpha: 0.22)),
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
                                          color: mine ? Colors.white70 : primary,
                                        ),
                                      ),
                                      Text(
                                        m.message,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: mine
                                              ? Colors.white
                                              : DebateTheme.textPrimary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          // "New messages" jump pill (like a messenger) — only when
                          // the user has scrolled up and a message came in.
                          if (_showJump)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 8,
                              child: Center(
                                child: Material(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(20),
                                  elevation: 3,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _jumpToBottom(),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            loc.newMessages,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.arrow_downward_rounded,
                                              color: Colors.white, size: 15),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                      style: IconButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                      ),
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
