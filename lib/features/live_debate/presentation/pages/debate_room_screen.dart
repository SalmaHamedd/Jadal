import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../../data/models/debate_models.dart';
import '../cubits/connection_cubit.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_access.dart';
import '../utils/debate_bell.dart';
import '../utils/debate_theme.dart';
import '../utils/debate_timeline.dart';
import '../widgets/debate_action_row.dart';
import '../widgets/grid_layout.dart';
import '../widgets/main_speaker_card.dart';
import '../widgets/news_ticker.dart';
import '../widgets/poi_widgets.dart';
import '../widgets/speakers_section.dart';
import '../widgets/top_bar_widgets.dart';
import 'result_room_screen.dart';

/// Layout 2 — the live debate room (§8.3). Body-only (no AppBar). Connects to
/// LiveKit on init and, for test mode (§9), treats the local user as the first
/// speaker with the timer running immediately.
/// The room's connection lifecycle, used to gate the body so a *failed* connect
/// never silently drops the user into a fake room (the old behaviour).
enum _ConnPhase { connecting, connected, failed }

class DebateRoomScreen extends StatefulWidget {
  final LiveJoinRole role;
  const DebateRoomScreen({super.key, this.role = LiveJoinRole.participant});

  @override
  State<DebateRoomScreen> createState() => _DebateRoomScreenState();
}

class _DebateRoomScreenState extends State<DebateRoomScreen> {
  _ConnPhase _phase = _ConnPhase.connecting;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  void _enter() {
    setState(() {
      _phase = _ConnPhase.connecting;
      _error = '';
    });
    // Mode-aware entry: test connects with the pasted creds + starts as the
    // first speaker; backend fetches the main-room token + connects + seeds.
    context.read<DebateController>().enterDebateRoom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<DebateController, DebateStates>(
              listenWhen: (_, s) => s is DebateTimelineEventState,
              listener: (context, state) {
                final e = (state as DebateTimelineEventState).event;
                if (e.ringsBell) DebateBell.instance.ring();
                final news = _newsFor(context.loc, e);
                if (news != null) context.read<DebateController>().updateLatestNews(news);
              },
            ),
            BlocListener<DebateController, DebateStates>(
              listenWhen: (_, s) => s is SpeakerChangedState,
              listener: (context, state) {
                final cubit = context.read<DebateController>();
                final slot = cubit.currentSlot;
                if (slot != null) {
                  cubit.updateLatestNews(
                    '${context.loc.nowSpeaking}: ${cubit.roleLabelForSlot(slot)}',
                  );
                }
              },
            ),
            BlocListener<DebateController, DebateStates>(
              listenWhen: (_, s) => s is POIAcceptedForLocalState,
              listener: (context, _) => showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<DebateController>(),
                  child: const PoiAskerMicDialog(),
                ),
              ),
            ),
            BlocListener<DebateController, DebateStates>(
              listenWhen: (_, s) => s is DebateFinishedState,
              listener: (context, _) => JadalSnackBar.show(
                context, context.loc.debateFinished,
                type: SnackBarType.success,
              ),
            ),
            BlocListener<DebateController, DebateStates>(
              listenWhen: (_, s) => s is DebateDisconnectedState,
              listener: (context, _) {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
            // Chair shared the result → everyone opens the result screen (confetti),
            // whose back button returns to the live open lobby (§U4b).
            BlocListener<DebateController, DebateStates>(
              listenWhen: (_, s) => s is NavigateToSharedResultState,
              listener: (context, _) {
                final cubit = context.read<DebateController>();
                final connection = context.read<ConnectionCubit>();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: cubit),
                      BlocProvider.value(value: connection),
                    ],
                    child: const ResultRoomScreen(),
                  ),
                ));
              },
            ),
            // Chair closed the room → everyone is taken back to the rooms list (§U4b).
            BlocListener<DebateController, DebateStates>(
              listenWhen: (_, s) => s is RoomClosedState,
              listener: (context, _) {
                JadalSnackBar.show(context, context.loc.roomClosedMsg,
                    type: SnackBarType.warning);
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
            // Connection lifecycle → drives the gate below. While connecting we
            // show a spinner; a connect-time failure shows the retry screen.
            // Errors AFTER a successful connect are action errors (not the room)
            // → surfaced as a snackbar without tearing the room down.
            BlocListener<DebateController, DebateStates>(
              listenWhen: (_, s) =>
                  s is DebateConnectingState ||
                  s is DebateConnectedState ||
                  s is DebateErrorState,
              listener: (context, state) {
                if (state is DebateConnectedState) {
                  if (_phase != _ConnPhase.connected) {
                    setState(() => _phase = _ConnPhase.connected);
                  }
                } else if (state is DebateConnectingState) {
                  if (_phase != _ConnPhase.connected) {
                    setState(() => _phase = _ConnPhase.connecting);
                  }
                } else if (state is DebateErrorState) {
                  if (_phase != _ConnPhase.connected) {
                    setState(() {
                      _phase = _ConnPhase.failed;
                      _error = state.message;
                    });
                  } else {
                    JadalSnackBar.show(context, state.message,
                        type: SnackBarType.error);
                  }
                }
              },
            ),
          ],
          child: _gatedBody(context),
        ),
      ),
    );
  }

  /// Gates the room body on the connection lifecycle so a failed connect can't
  /// masquerade as a joined room.
  Widget _gatedBody(BuildContext context) {
    switch (_phase) {
      case _ConnPhase.connecting:
        return const _ConnectingView();
      case _ConnPhase.failed:
        return _ConnectionFailedView(message: _error, onRetry: _enter);
      case _ConnPhase.connected:
        return GestureDetector(
          onTap: () => context.read<ConnectionCubit>().toggleActionsVisibility(),
          behavior: HitTestBehavior.opaque,
          child: BlocBuilder<DebateController, DebateStates>(
            // Rebuild the lobby↔debate switch on everything that changes which
            // view we show OR who's in it: mode flips, live-state refreshes (the
            // chair's own next-stage), and presence (joins/leaves) — but not on
            // per-second timer ticks (the inner cards handle those). This is what
            // makes a joiner appear in the grid and the chair's screen flip.
            buildWhen: (_, s) =>
                s is LobbyModeChangedState ||
                s is DebateConnectedState ||
                s is LiveStateUpdatedState ||
                s is RemoteTrackReceivedState ||
                s is SpeakerChangedState,
            builder: (context, state) {
              final cubit = context.read<DebateController>();
              return cubit.isLobbyMode ? _LobbyModeView() : _DebateView();
            },
          ),
        );
    }
  }

  String? _newsFor(AppLocalizations loc, DebateTimelineEvent e) => switch (e) {
        DebateTimelineEvent.speechStarted => null, // covered by speaker-change news
        DebateTimelineEvent.poisOpened => loc.newsPoisOpen,
        DebateTimelineEvent.lastChancePoi => loc.newsLastChance,
        DebateTimelineEvent.poisClosed => loc.newsPoisClosed,
        DebateTimelineEvent.mainTimeEnded => loc.newsMainEnded,
        DebateTimelineEvent.extraTimeEnded => loc.newsExtraEnded,
      };
}

class _DebateView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebateController>();
    return Column(
      children: [
        // (A) Top row: audience button | news ticker | motion button. The bottom
        // gap matches the main↔speakers gap (16) so the news ticker's update glow
        // never touches the main speaker card below it (§U / news spacing).
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
          child: Row(
            children: [
              AudienceButton(cubit: cubit),
              const SizedBox(width: 8),
              const Expanded(child: NewsTicker()),
              const SizedBox(width: 8),
              MotionButton(motion: cubit.data.motion),
            ],
          ),
        ),
        // (B) Main speaker card + timer. The extra gap + bottom breathing room
        // below are taken from this card (lower flex), not the speaker cards (§U4b).
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const MainSpeakerCard(),
          ),
        ),
        // Gap between the main card and the speakers (≈2× the old spacing).
        const SizedBox(height: 16),
        // (C) Speakers section: 3 prop (left) / 3 opp (right).
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const SpeakersSection(),
          ),
        ),
        // Bottom breathing room so the third speaker cards aren't on the edge
        // (≈half the main↔speakers gap).
        const SizedBox(height: 8),
        // (D) Auto-hiding bottom action row.
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
    );
  }
}

/// Open-lobby mode (§8.5): everyone in the grid; a judge-only "Back to debate"
/// button at the top returns everyone to the debate layout.
class _LobbyModeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateController>();
    // Only show people who are ACTUALLY in the room (mock mode reports everyone
    // present, so it still renders the full roster for the demo). `isLocal` is
    // resolved from the real user id, not the "prop speaker 0" assumption.
    final tiles = <GridParticipant>[
      // Judges pinned to the top (§9.4), then prop / opp / audience.
      for (final j in cubit.data.judges)
        if (cubit.isUserPresent(j.id))
          GridParticipant(id: j.id, name: j.name, isLocal: cubit.isLocalUserId(j.id)),
      for (final side in DebateSide.values)
        for (final d in cubit.teamFor(side).debaters)
          if (cubit.isUserPresent(d.id))
            GridParticipant(id: d.id, name: d.name, isLocal: cubit.isLocalUserId(d.id)),
      for (final a in cubit.data.audience)
        if (cubit.isUserPresent(a.id))
          GridParticipant(id: a.id, name: a.name, isLocal: cubit.isLocalUserId(a.id)),
    ];
    // FE-3: append anyone *present in the room* who isn't on the roster (a plain
    // viewer with no judge/debater/audience entry) using their LiveKit identity,
    // so a present participant is never invisible to the others' grid.
    final shownIds = {for (final t in tiles) t.id};
    for (final p in cubit.participants) {
      final id = p.identity;
      if (id.isEmpty || shownIds.contains(id)) continue;
      shownIds.add(id);
      tiles.add(GridParticipant(
        id: id,
        name: p.name.isNotEmpty ? p.name : cubit.firstName(p.name),
        isLocal: cubit.isLocalUserId(id),
      ));
    }
    return Column(
      children: [
        // "Back to debate" is chair-only — and gone once the debate has ended,
        // since the room then stays in the open lobby (§U4b).
        if (cubit.canControlStage && !cubit.debateFinished)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => cubit.setLobbyMode(false),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(loc.backToDebate),
              ),
            ),
          ),
        Expanded(child: GridLayout(participants: tiles)),
        // Auto-hiding action row (§9.3) — toggled by the screen's outer tap.
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
    );
  }
}

/// Shown while the room token is fetched + the LiveKit connect is in flight.
class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              loc.connectingToRoom,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: DebateTheme.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the connect failed — the user is NOT in the room. Offers an
/// explicit retry or a way out instead of a silently-broken room.
class _ConnectionFailedView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ConnectionFailedView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFFE53935)),
            const SizedBox(height: 16),
            Text(
              loc.connectionFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: DebateTheme.textPrimary(context),
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: DebateTheme.textSecondary(context),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(loc.leaveSession),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(loc.retry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
