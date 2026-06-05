import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_gradient_button.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../../../../di/injection_container.dart' as di;
import '../../data/models/debate_models.dart';
import '../cubits/connection_cubit.dart';
import '../cubits/debate_cubit.dart';
import '../utils/debate_access.dart';
import '../utils/debate_theme.dart';
import 'debate_room_screen.dart';
import 'prep_room_screen.dart';
import 'result_room_screen.dart';

/// Lobby / rooms list (§8.1). The entry point of the feature — provides the
/// shared [DebateCubit] + [ConnectionCubit] that persist across the room
/// screens, and gates each room with the [DebateAccess] rules.
class DebateLobbyScreen extends StatelessWidget {
  const DebateLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<DebateCubit>()),
        BlocProvider(create: (_) => di.sl<ConnectionCubit>()),
      ],
      child: const _LobbyView(),
    );
  }
}

class _LobbyView extends StatelessWidget {
  const _LobbyView();

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateCubit>();
    final data = cubit.data;

    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      appBar: AppBar(
        title: Text(loc.lobbyTitle,
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
      ),
      body: BlocBuilder<DebateCubit, DebateStates>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final room in data.rooms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _RoomCard(room: room),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final DebateRoom room;
  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateCubit>();
    final access = _evaluate(context, cubit);

    final (IconData icon, Color color) = switch (room.type) {
      DebateRoomType.proposition => (Icons.shield_rounded, JadalColors.propositionBlue),
      DebateRoomType.opposition => (Icons.gavel_rounded, JadalColors.oppositionOrange),
      DebateRoomType.liveDebate => (Icons.podcasts_rounded, JadalColors.deepBlue),
      DebateRoomType.result => (Icons.emoji_events_rounded, JadalColors.judgesGrey),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DebateTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(loc),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: DebateTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(access.locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                        size: 13, color: DebateTheme.textSecondary(context)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        access.status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: DebateTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: JadalGradientButton(
              text: loc.join,
              height: 42,
              onPressed: access.onJoin,
            ),
          ),
        ],
      ),
    );
  }

  String _title(AppLocalizations loc) {
    switch (room.type) {
      case DebateRoomType.proposition:
        return '${loc.proposition} (${room.team?.teamName ?? ''})';
      case DebateRoomType.opposition:
        return '${loc.opposition} (${room.team?.teamName ?? ''})';
      case DebateRoomType.liveDebate:
        return loc.liveDebateRoom;
      case DebateRoomType.result:
        return loc.resultRoomTitle;
    }
  }

  _RoomAccess _evaluate(BuildContext context, DebateCubit cubit) {
    final loc = context.loc;
    final data = cubit.data;
    final userId = data.currentUserId;
    final now = DateTime.now();

    switch (room.type) {
      case DebateRoomType.proposition:
      case DebateRoomType.opposition:
        final team = room.team!;
        if (!DebateAccess.canJoinTeamRoom(team, userId)) {
          return _RoomAccess(status: loc.onlyTeamMembers, locked: true, onJoin: null);
        }
        final open = DebateAccess.prepOpen(data.format, data.debateStartTime, now);
        if (!open) {
          return _RoomAccess(status: loc.prepClosed, locked: true, onJoin: null);
        }
        return _RoomAccess(
          status: loc.statusOpen,
          locked: false,
          onJoin: () => _push(context, cubit, PrepRoomScreen(side: team.side)),
        );

      case DebateRoomType.liveDebate:
        final role = DebateAccess.resolveLiveJoinRole(
          judgeIds: room.judgeIds,
          propTeam: data.propositionTeam,
          oppTeam: data.oppositionTeam,
          propOrder: cubit.propOrder,
          oppOrder: cubit.oppOrder,
          userId: userId,
        );
        if (role == LiveJoinRole.blockedNeedsOrder) {
          return _RoomAccess(
            status: loc.orderNotSet,
            locked: true,
            onJoin: () => _showNeedsOrder(context, cubit),
          );
        }
        return _RoomAccess(
          status: loc.statusOpen,
          locked: false,
          onJoin: () => _pushRoom(context, cubit, role),
        );

      case DebateRoomType.result:
        if (!DebateAccess.resultRoomOpen(cubit.debateFinished)) {
          return _RoomAccess(status: loc.resultsNotReady, locked: true, onJoin: null);
        }
        // Judges-only is enforced here; in test the user may not be a judge, so
        // we allow viewing the finished results screen.
        // TODO(role-gating): restrict to judges present at finish.
        return _RoomAccess(
          status: loc.statusOpen,
          locked: false,
          onJoin: () => _push(context, cubit, const ResultRoomScreen()),
        );
    }
  }

  void _showNeedsOrder(BuildContext context, DebateCubit cubit) {
    final loc = context.loc;
    final data = cubit.data;
    final side = data.propositionTeam.debaterById(data.currentUserId) != null
        ? DebateSide.proposition
        : DebateSide.opposition;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DebateTheme.surface(context),
        title: Text(loc.needOrderTitle, style: const TextStyle(fontFamily: 'Cairo')),
        content: Text(loc.needOrderBody, style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).maybePop();
              _push(context, cubit, PrepRoomScreen(side: side));
            },
            child: Text(loc.goToPrep),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, DebateCubit cubit, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: cubit, child: screen),
    ));
  }

  void _pushRoom(BuildContext context, DebateCubit cubit, LiveJoinRole role) {
    final connection = context.read<ConnectionCubit>();
    if (role == LiveJoinRole.audience) {
      JadalSnackBar.show(context, context.loc.joiningAsAudience, type: SnackBarType.success);
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: connection),
        ],
        child: DebateRoomScreen(role: role),
      ),
    ));
  }
}

class _RoomAccess {
  final String status;
  final bool locked;
  final VoidCallback? onJoin;
  const _RoomAccess({required this.status, required this.locked, required this.onJoin});
}
