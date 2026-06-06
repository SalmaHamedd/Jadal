import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubits/debate_cubit.dart';
import '../utils/debate_theme.dart';
import '../widgets/grid_layout.dart';

/// Result room (§8.1). Locked until the chair marks the debate done; then shows
/// the judges (Layout 1 grid). Access is judge-only and is gated in the lobby.
class ResultRoomScreen extends StatelessWidget {
  const ResultRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateCubit>();
    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      appBar: AppBar(
        title: Text(loc.resultRoomTitle,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
      ),
      body: BlocBuilder<DebateCubit, DebateStates>(
        builder: (context, state) {
          if (!cubit.debateFinished) {
            return _NotReady();
          }
          final tiles = [
            for (final j in cubit.data.judges) GridParticipant(id: j.id, name: j.name),
          ];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(loc.results,
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: DebateTheme.textPrimary(context))),
              ),
              Expanded(child: GridLayout(participants: tiles)),
            ],
          );
        },
      ),
    );
  }
}

class _NotReady extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock_rounded, size: 64, color: JadalColors.judgesGrey),
            const SizedBox(height: 16),
            Text(loc.resultsNotReady,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: DebateTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text(loc.resultsNotReadyBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Cairo', color: DebateTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }
}
