import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/debate_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../di/injection_container.dart' as di;
import '../../domain/entities/debater.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/repositories/debate_repositories.dart';
import '../cubits/coach_cubit.dart';
import '../widgets/arabic_format.dart';

class CoachTeamScreen extends StatelessWidget {
  const CoachTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoachTeamCubit>(
      create: (_) => CoachTeamCubit(di.sl<CoachRepository>())..load(),
      child: const _CoachTeamView(),
    );
  }
}

class _CoachTeamView extends StatelessWidget {
  const _CoachTeamView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachTeamCubit, CoachTeamState>(
      listenWhen: (a, b) => a.lastAction != b.lastAction && b.lastAction != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(state.lastAction!)));
        context.read<CoachTeamCubit>().clearLastAction();
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('فريقي'),
            actions: [
              if (state.team != null)
                TextButton.icon(
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('إدارة الأولويات'),
                  onPressed: () => _openReorder(context, state),
                ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(state.team?.name ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text('عدد الأعضاء: ${state.team!.debaters.length} / $kTeamSize',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    for (final d in state.team!.debaters) _MemberTile(debater: d),
                    const SizedBox(height: 24),
                    Text(
                      'طلبات الانضمام (${state.joinRequests.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (state.joinRequests.isEmpty)
                      Text('لا توجد طلبات حالياً.',
                          style: Theme.of(context).textTheme.bodySmall)
                    else
                      for (final r in state.joinRequests) _JoinRequestTile(r: r),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _openReorder(BuildContext context, CoachTeamState state) async {
    final cubit = context.read<CoachTeamCubit>();
    final initial = List<Debater>.from(state.team!.debaters);
    final result = await Navigator.of(context).push<List<Debater>>(
      MaterialPageRoute(
        builder: (_) => _ReorderPage(initial: initial),
      ),
    );
    if (result != null && result.length == kTeamSize) {
      cubit.reorderPriorities(result);
    }
  }
}

class _MemberTile extends StatelessWidget {
  final Debater debater;
  const _MemberTile({required this.debater});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: JadalColors.primaryBlue,
            child: Text(
              debater.name.characters.first,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debater.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: JadalColors.primaryOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'أولوية ${debater.priority + 1}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: JadalColors.primaryOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      debater.isOnline ? 'نشط' : 'غير نشط',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: debater.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinRequestTile extends StatelessWidget {
  final JoinRequest r;
  const _JoinRequestTile({required this.r});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CoachTeamCubit>();
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add, color: JadalColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.debaterName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(formatTime(r.createdAt),
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          TextButton(
              onPressed: () => cubit.declineRequest(r.id),
              child: const Text('ارفض')),
          ElevatedButton(
            onPressed: () => cubit.acceptRequest(r.id),
            child: const Text('اقبل'),
          ),
        ],
      ),
    );
  }
}

class _ReorderPage extends StatefulWidget {
  final List<Debater> initial;
  const _ReorderPage({required this.initial});

  @override
  State<_ReorderPage> createState() => _ReorderPageState();
}

class _ReorderPageState extends State<_ReorderPage> {
  late List<Debater> _order;

  @override
  void initState() {
    super.initState();
    _order = List<Debater>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأولويات'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_order),
            child: const Text('حفظ'),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _order.length,
        onReorder: (oldI, newI) {
          setState(() {
            if (newI > oldI) newI--;
            final item = _order.removeAt(oldI);
            _order.insert(newI, item);
          });
        },
        itemBuilder: (context, i) {
          final d = _order[i];
          return Container(
            key: ValueKey(d.id),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border:
                  Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text('${i + 1}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: JadalColors.primaryBlue)),
                const SizedBox(width: 14),
                Expanded(child: Text(d.name)),
                const Icon(Icons.drag_handle),
              ],
            ),
          );
        },
      ),
    );
  }
}
