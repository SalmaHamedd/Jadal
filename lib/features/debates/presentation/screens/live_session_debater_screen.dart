import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../di/injection_container.dart' as di;
import '../../domain/entities/debate.dart';
import '../../domain/entities/debater.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/repositories/debate_repositories.dart';
import '../cubits/live_session_debater_cubit.dart';
import '../widgets/arabic_format.dart';
import '../widgets/participant_tile.dart';

class LiveSessionDebaterScreen extends StatelessWidget {
  final Debate debate;
  const LiveSessionDebaterScreen({super.key, required this.debate});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveSessionDebaterCubit>(
      create: (_) => LiveSessionDebaterCubit(
        repo: di.sl<LiveSessionRepository>(),
        debateId: debate.id,
      )..load(),
      child: _LiveSessionView(debate: debate),
    );
  }
}

class _LiveSessionView extends StatelessWidget {
  final Debate debate;
  const _LiveSessionView({required this.debate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          debate.title,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: BlocBuilder<LiveSessionDebaterCubit, LiveSessionDebaterState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              Column(
                children: [
                  _PhaseIndicator(current: state.phase),
                  Expanded(child: _ParticipantsGrid(state: state)),
                  _BottomToolbar(state: state),
                ],
              ),
              if (state.notesOpen) _NotesPanel(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final SessionPhase current;
  const _PhaseIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          for (final p in SessionPhase.values) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: p == current
                      ? JadalColors.primaryOrange
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p.arabicLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: p == current
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (p != SessionPhase.closing) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _ParticipantsGrid extends StatelessWidget {
  final LiveSessionDebaterState state;
  const _ParticipantsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final gov = state.participants
        .where((p) =>
            p.role == ParticipantRole.debater && p.team == TeamSide.government)
        .toList();
    final opp = state.participants
        .where((p) =>
            p.role == ParticipantRole.debater && p.team == TeamSide.opposition)
        .toList();
    final judge =
        state.participants.where((p) => p.role == ParticipantRole.judge).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _Column(title: 'الحكومة', items: gov)),
                const SizedBox(width: 10),
                Expanded(child: _Column(title: 'المعارضة', items: opp)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (judge.isNotEmpty)
            ParticipantTile(participant: judge.first, showActiveBorder: false),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final List<LiveParticipant> items;
  const _Column({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (context, i) => ParticipantTile(participant: items[i]),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
          ),
        ),
      ],
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final LiveSessionDebaterState state;
  const _BottomToolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveSessionDebaterCubit>();
    final canPOI =
        !state.isMySpeakingTurn && state.poiStatus == POIStatus.idle;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            _ToolbarBtn(
              icon: state.isMyMicOn ? Icons.mic : Icons.mic_off,
              active: state.isMyMicOn,
              onTap: cubit.toggleMic,
            ),
            const SizedBox(width: 8),
            _ToolbarBtn(
              icon: state.isMyCameraOn ? Icons.videocam : Icons.videocam_off,
              active: state.isMyCameraOn,
              onTap: cubit.toggleCamera,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canPOI ? cubit.requestPOI : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _poiColor(state.poiStatus),
                ),
                icon: _poiIcon(state.poiStatus),
                label: Text(_poiLabel(state.poiStatus, canPOI)),
              ),
            ),
            const SizedBox(width: 8),
            _ToolbarBtn(
              icon: Icons.sticky_note_2_outlined,
              active: state.notesOpen,
              onTap: cubit.toggleNotes,
            ),
          ],
        ),
      ),
    );
  }

  Color _poiColor(POIStatus s) => switch (s) {
        POIStatus.idle => JadalColors.primaryOrange,
        POIStatus.pending => Colors.amber.shade700,
        POIStatus.accepted => Colors.green.shade600,
        POIStatus.declined => Colors.red.shade400,
      };

  Widget _poiIcon(POIStatus s) {
    if (s == POIStatus.pending) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    return const Icon(Icons.front_hand, size: 16);
  }

  String _poiLabel(POIStatus s, bool canPOI) {
    if (!canPOI && s == POIStatus.idle) return 'POI (دورك)';
    return switch (s) {
      POIStatus.idle => 'اطلب نقطة استفسار',
      POIStatus.pending => 'بانتظار الحكم…',
      POIStatus.accepted => 'تم القبول',
      POIStatus.declined => 'رُفض',
    };
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToolbarBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? JadalColors.primaryBlue.withValues(alpha: 0.12)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: active
                ? JadalColors.primaryBlue
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _NotesPanel extends StatefulWidget {
  final LiveSessionDebaterState state;
  const _NotesPanel({required this.state});

  @override
  State<_NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<_NotesPanel> {
  final _controller = TextEditingController();
  String? _selectedTeammate;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _teammates() {
    return widget.state.participants
        .where((p) =>
            p.role == ParticipantRole.debater &&
            p.team == TeamSide.government &&
            p.id != widget.state.myDebaterId)
        .map((p) => p.name)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teammates = _teammates();
    _selectedTeammate ??= teammates.isNotEmpty ? teammates.first : null;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => context.read<LiveSessionDebaterCubit>().toggleNotes(),
        child: ColoredBox(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('ملاحظات للزملاء',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              context.read<LiveSessionDebaterCubit>().toggleNotes(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTeammate,
                      items: teammates
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTeammate = v),
                      decoration:
                          const InputDecoration(labelText: 'إلى'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      minLines: 2,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(hintText: 'اكتب الملاحظة…'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final to = _selectedTeammate;
                        if (to == null) return;
                        await context
                            .read<LiveSessionDebaterCubit>()
                            .sendNote(toName: to, text: _controller.text);
                        _controller.clear();
                      },
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('إرسال'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: widget.state.notes.length,
                        itemBuilder: (context, i) {
                          final n = widget.state.notes[i];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: n.fromMe
                                  ? JadalColors.primaryOrange
                                  : JadalColors.primaryBlue,
                              child: Text(
                                n.fromName.characters.first,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: 'Cairo'),
                              ),
                            ),
                            title: Text('${n.fromName} → ${n.toName}',
                                style: theme.textTheme.labelSmall),
                            subtitle: Text(n.text),
                            trailing: Text(formatTime(n.createdAt),
                                style: theme.textTheme.labelSmall),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
