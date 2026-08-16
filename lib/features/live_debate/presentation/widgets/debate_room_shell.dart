import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/jadal_gradient_background.dart';
import '../cubits/connection_cubit.dart';
import 'debate_action_row.dart';

/// Wraps a room body with the tap-to-reveal / auto-hiding bottom action row so
/// the (role-appropriate) tool bar is available in **every** room — open-lobby,
/// prep and result — not just the live debate. Requires a [ConnectionCubit]
/// above it in the tree. Also paints the shared brand-gradient backdrop so prep
/// and result rooms match the rest of the live-debate feature.
class DebateRoomShell extends StatelessWidget {
  final Widget child;
  const DebateRoomShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<ConnectionCubit>().toggleActionsVisibility(),
      child: JadalGradientBackground(
        child: Column(
          children: [
            Expanded(child: child),
            BlocBuilder<ConnectionCubit, ConnectionStates>(
              builder: (context, _) {
                final connection = context.read<ConnectionCubit>();
                // Reveal the row top-down so the room body above it slides up
                // smoothly to make space (instead of the bar popping in).
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: connection.showActions ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeInOutCubic,
                  builder: (context, t, _) => GestureDetector(
                    onTap: connection.resetHideTimer,
                    behavior: HitTestBehavior.opaque,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: t.clamp(0.0, 1.0),
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: const DebateActionRow(visible: true),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
