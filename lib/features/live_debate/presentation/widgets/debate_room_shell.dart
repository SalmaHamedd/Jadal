import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/connection_cubit.dart';
import 'debate_action_row.dart';

/// Wraps a room body with the tap-to-reveal / auto-hiding bottom action row so
/// the (role-appropriate) tool bar is available in **every** room — open-lobby,
/// prep and result — not just the live debate (§9.3). Requires a [ConnectionCubit]
/// above it in the tree.
class DebateRoomShell extends StatelessWidget {
  final Widget child;
  const DebateRoomShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<ConnectionCubit>().toggleActionsVisibility(),
      child: Column(
        children: [
          Expanded(child: child),
          BlocBuilder<ConnectionCubit, ConnectionStates>(
            builder: (context, _) {
              final connection = context.read<ConnectionCubit>();
              return GestureDetector(
                onTap: connection.resetHideTimer,
                child: DebateActionRow(visible: connection.showActions),
              );
            },
          ),
        ],
      ),
    );
  }
}
