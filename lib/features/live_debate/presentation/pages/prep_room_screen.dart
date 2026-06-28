import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/debate_models.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_access.dart';
import '../utils/debate_theme.dart';
import '../widgets/debate_room_shell.dart';
import '../widgets/grid_layout.dart';
import '../widgets/speaker_order_dialog.dart';

/// Prep room (Layout 1, §8.1). Shows the team grid, a prep countdown, and — for
/// the current leader only — the speaker-order control. The control reacts live
/// to presence (recomputed from the cubit's presentIds).
class PrepRoomScreen extends StatefulWidget {
  final DebateSide side;
  const PrepRoomScreen({super.key, required this.side});

  @override
  State<PrepRoomScreen> createState() => _PrepRoomScreenState();
}

class _PrepRoomScreenState extends State<PrepRoomScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Drive the prep countdown.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateController>();
    final team = cubit.teamFor(widget.side);
    final remaining = DebateAccess.prepRemaining(
      cubit.data.format,
      cubit.data.debateStartTime,
      DateTime.now(),
    );

    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      appBar: AppBar(
        backgroundColor: DebateTheme.sideColor(widget.side),
        // Side colours (blue/opp orange) are too dark for navy text → force white.
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${loc.prepRoomTitle} (${team.teamName})',
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      body: DebateRoomShell(
        child: BlocBuilder<DebateController, DebateStates>(
        builder: (context, state) {
          final present = cubit.presentIds;
          final leader = DebateAccess.currentLeader(team, present);
          final isLeader = leader?.id == cubit.data.currentUserId;
          final order = cubit.orderFor(widget.side);
          // Issue 1: show who is ACTUALLY in the prep room (real LiveKit
          // presence), not the whole roster — same rule the live room uses. The
          // prep room is connected (the lobby joins it before pushing), and mock
          // mode reports everyone present so the solo demo is unchanged.
          final tiles = [
            for (final d in team.debaters)
              if (cubit.isUserPresent(d.id))
                GridParticipant(id: d.id, name: d.name, isLocal: d.id == cubit.data.currentUserId),
          ];

          return Column(
            children: [
              _PrepBanner(
                remainingLabel: _fmt(remaining),
                orderSet: order.isSet,
                leaderName: leader?.name,
                isLeader: isLeader,
                accent: DebateTheme.sideColor(widget.side),
              ),
              Expanded(child: GridLayout(participants: tiles)),
              if (isLeader)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    // Solid side colour — no gradient in the prep room (§U4a).
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: DebateTheme.sideColor(widget.side),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.reorder_rounded),
                      label: Text(
                        order.isSet ? loc.updateSpeakerOrder : loc.selectSpeakerOrder,
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => SpeakerOrderDialog(
                          team: team,
                          current: order,
                          replyEnabled: cubit.data.format.replySpeech,
                          slotCount: cubit.speakersPerSide, // FE-8: N slots, dup allowed
                          onConfirm: (ordered, replyId) => cubit.setSpeakerOrder(
                            teamId: team.teamId,
                            orderedSpeakerIds: ordered,
                            replySpeakerId: replyId,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        ),
      ),
    );
  }
}

class _PrepBanner extends StatelessWidget {
  final String remainingLabel;
  final bool orderSet;
  final String? leaderName;
  final bool isLeader;
  final Color accent;
  const _PrepBanner({
    required this.remainingLabel,
    required this.orderSet,
    required this.leaderName,
    required this.isLeader,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DebateTheme.surfaceElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: accent),
              const SizedBox(width: 8),
              Text('${loc.prepEndsIn}: $remainingLabel',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      color: DebateTheme.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(orderSet ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 18,
                  color: orderSet ? const Color(0xFF2E9E5B) : JadalColors.primaryOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  orderSet ? loc.orderSet : loc.orderNotSet,
                  style: TextStyle(
                      fontFamily: 'Cairo', color: DebateTheme.textSecondary(context), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isLeader ? loc.leaderHint : '${loc.notLeaderHint} ${leaderName ?? '—'}',
            style: TextStyle(
                fontFamily: 'Cairo', color: DebateTheme.textSecondary(context), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
