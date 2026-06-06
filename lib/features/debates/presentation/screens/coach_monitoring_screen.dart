import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../di/injection_container.dart' as di;
import '../../domain/entities/debate.dart';
import '../../domain/entities/debater.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/repositories/debate_repositories.dart';
import '../cubits/coach_cubit.dart';
import '../widgets/arabic_format.dart';
import '../widgets/participant_tile.dart';

class CoachMonitoringScreen extends StatelessWidget {
  final Debate debate;
  const CoachMonitoringScreen({super.key, required this.debate});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoachMonitoringCubit>(
      create: (_) => CoachMonitoringCubit(
        repo: di.sl<CoachRepository>(),
        debateId: debate.id,
      )..load(),
      child: _CoachMonitoringView(debate: debate),
    );
  }
}

class _CoachMonitoringView extends StatelessWidget {
  final Debate debate;
  const _CoachMonitoringView({required this.debate});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachMonitoringCubit, CoachMonitoringState>(
      listenWhen: (a, b) => a.lastAction != b.lastAction && b.lastAction != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(state.lastAction!)));
        context.read<CoachMonitoringCubit>().clearLastAction();
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(debate.title,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: JadalColors.primaryOrange,
            onPressed: state.isLoading
                ? null
                : () => _openSendNoteSheet(context, state),
            icon: const Icon(Icons.send),
            label: const Text('ملاحظة للمناظر'),
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 600;
                    final activity = _ActivityFeed(events: state.activity);
                    final grid = _ReadOnlyGrid(state: state);
                    return wide
                        ? Row(
                            children: [
                              Expanded(flex: 3, child: grid),
                              Expanded(flex: 2, child: activity),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                            children: [
                              grid,
                              const SizedBox(height: 16),
                              activity,
                            ],
                          );
                  },
                ),
        );
      },
    );
  }

  Future<void> _openSendNoteSheet(
      BuildContext context, CoachMonitoringState state) async {
    final cubit = context.read<CoachMonitoringCubit>();
    final controller = TextEditingController();
    final govDebaters = state.participants
        .where((p) =>
            p.role == ParticipantRole.debater &&
            p.team == TeamSide.government)
        .map((p) => p.name)
        .toList();
    String? selected = govDebaters.isNotEmpty ? govDebaters.first : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('ملاحظة للمناظر',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  items: govDebaters
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) => setState(() => selected = v),
                  decoration: const InputDecoration(labelText: 'المناظر'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(hintText: 'اكتب الملاحظة…'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('إرسال'),
                  onPressed: () {
                    if (selected != null) {
                      cubit.sendNote(
                        toDebaterName: selected!,
                        text: controller.text,
                      );
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReadOnlyGrid extends StatelessWidget {
  final CoachMonitoringState state;
  const _ReadOnlyGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final debaters = state.participants
        .where((p) => p.role == ParticipantRole.debater)
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 130,
        ),
        itemCount: debaters.length,
        itemBuilder: (context, i) => ParticipantTile(participant: debaters[i]),
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  final List<ActivityEvent> events;
  const _ActivityFeed({required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 16),
              const SizedBox(width: 6),
              Text('سجل الأحداث',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: JadalColors.primaryOrange,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatTime(e.timestamp),
                            style: theme.textTheme.labelSmall),
                        Text(e.description, style: theme.textTheme.bodySmall),
                      ],
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
