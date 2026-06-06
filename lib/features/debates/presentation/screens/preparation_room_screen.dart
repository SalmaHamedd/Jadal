import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../di/injection_container.dart' as di;
import '../../domain/entities/debate.dart';
import '../../domain/entities/debater.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/debate_repositories.dart';
import '../cubits/preparation_room_cubit.dart';
import '../widgets/arabic_format.dart';
import '../widgets/team_colors.dart';
import 'live_session_debater_screen.dart';

class PreparationRoomScreen extends StatelessWidget {
  final Debate debate;

  const PreparationRoomScreen({super.key, required this.debate});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PreparationRoomCubit>(
      create: (_) => PreparationRoomCubit(
        repo: di.sl<PreparationRoomRepository>(),
        debateId: debate.id,
      )..load(),
      child: _PrepRoomView(debate: debate),
    );
  }
}

class _PrepRoomView extends StatelessWidget {
  final Debate debate;
  const _PrepRoomView({required this.debate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('غرفة التحضير')),
      body: BlocBuilder<PreparationRoomCubit, PreparationRoomState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _Header(debate: debate, countdown: state.countdownSeconds),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _TeamColumn(team: debate.governmentTeam)),
                    const SizedBox(width: 12),
                    Expanded(child: _TeamColumn(team: debate.oppositionTeam)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _ChatPanel(messages: state.messages)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: state.canEnterSession
                        ? () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    LiveSessionDebaterScreen(debate: debate),
                              ),
                            )
                        : null,
                    icon: const Icon(Icons.login),
                    label: const Text('دخول الجلسة'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Debate debate;
  final int countdown;

  const _Header({required this.debate, required this.countdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            debate.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${debate.motionFramework} • ${debate.governmentTeam.name} × ${debate.oppositionTeam.name}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: countdown > 0
                  ? JadalColors.primaryBlue.withValues(alpha: 0.10)
                  : JadalColors.primaryOrange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  countdown > 0 ? Icons.timer : Icons.flag_circle,
                  color: countdown > 0
                      ? JadalColors.primaryBlue
                      : JadalColors.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  countdown > 0
                      ? 'بدء الجلسة بعد'
                      : 'يمكنك الدخول إلى الجلسة الآن',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  countdown > 0 ? formatCountdown(countdown) : '00:00',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: countdown > 0
                        ? JadalColors.primaryBlue
                        : JadalColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final Team team;
  const _TeamColumn({required this.team});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TeamColors.of(team.side, isDark: isDark);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: colors.base, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                team.side.arabicLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final d in team.debaters)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: d.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      d.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatPanel extends StatefulWidget {
  final List<PrepChatMessage> messages;
  const _ChatPanel({required this.messages});

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<PreparationRoomCubit>().sendMessage(text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 16),
                SizedBox(width: 6),
                Text('محادثة الفريق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(10),
              itemCount: widget.messages.length,
              itemBuilder: (context, i) {
                final m = widget.messages[i];
                return _MessageBubble(message: m);
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة…',
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: JadalColors.primaryOrange),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final PrepChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final theme = Theme.of(context);
    final bg = isMine
        ? JadalColors.primaryOrange.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest;
    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.authorName,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: JadalColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.text,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              formatTime(message.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
