import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../../debate_test_credentials.dart';
import '../../data/models/debate_models.dart';
import '../cubits/connection_cubit.dart';
import '../cubits/debate_cubit.dart';
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

/// Layout 2 — the live debate room (§8.3). Body-only (no AppBar). Connects to
/// LiveKit on init and, for test mode (§9), treats the local user as the first
/// speaker with the timer running immediately.
class DebateRoomScreen extends StatefulWidget {
  final LiveJoinRole role;
  const DebateRoomScreen({super.key, this.role = LiveJoinRole.participant});

  @override
  State<DebateRoomScreen> createState() => _DebateRoomScreenState();
}

class _DebateRoomScreenState extends State<DebateRoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = context.read<DebateCubit>();
      if (kHasLiveKitCredentials) {
        await cubit.connectToRoom(url: kLiveKitUrl, token: kLiveKitToken);
      }
      // §9: start as the first speaker so the full timer state machine runs.
      cubit.startAsFirstSpeaker();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<DebateCubit, DebateStates>(
              listenWhen: (_, s) => s is DebateTimelineEventState,
              listener: (context, state) {
                final e = (state as DebateTimelineEventState).event;
                if (e.ringsBell) DebateBell.instance.ring();
                final news = _newsFor(context.loc, e);
                if (news != null) context.read<DebateCubit>().updateLatestNews(news);
              },
            ),
            BlocListener<DebateCubit, DebateStates>(
              listenWhen: (_, s) => s is SpeakerChangedState,
              listener: (context, state) {
                final cubit = context.read<DebateCubit>();
                final slot = cubit.currentSlot;
                if (slot != null) {
                  cubit.updateLatestNews(
                    '${context.loc.nowSpeaking}: ${cubit.roleLabelForSlot(slot)}',
                  );
                }
              },
            ),
            BlocListener<DebateCubit, DebateStates>(
              listenWhen: (_, s) => s is POIAcceptedForLocalState,
              listener: (context, _) => showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<DebateCubit>(),
                  child: const PoiAskerMicDialog(),
                ),
              ),
            ),
            BlocListener<DebateCubit, DebateStates>(
              listenWhen: (_, s) => s is DebateFinishedState,
              listener: (context, _) => JadalSnackBar.show(
                context, context.loc.debateFinished,
                type: SnackBarType.success,
              ),
            ),
            BlocListener<DebateCubit, DebateStates>(
              listenWhen: (_, s) => s is DebateDisconnectedState,
              listener: (context, _) {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
          ],
          child: GestureDetector(
            onTap: () => context.read<ConnectionCubit>().toggleActionsVisibility(),
            behavior: HitTestBehavior.opaque,
            child: BlocBuilder<DebateCubit, DebateStates>(
              buildWhen: (_, s) => s is LobbyModeChangedState || s is DebateConnectedState,
              builder: (context, state) {
                final cubit = context.read<DebateCubit>();
                return cubit.isLobbyMode ? _LobbyModeView() : _DebateView();
              },
            ),
          ),
        ),
      ),
    );
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
    final cubit = context.read<DebateCubit>();
    return Column(
      children: [
        // (A) Top row: audience button | news ticker | motion button.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              AudienceButton(audience: cubit.data.audience),
              const SizedBox(width: 8),
              const Expanded(child: NewsTicker()),
              const SizedBox(width: 8),
              MotionButton(motion: cubit.data.motion),
            ],
          ),
        ),
        // (B) Main speaker card + timer.
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const MainSpeakerCard(),
          ),
        ),
        // (C) Speakers section: 3 prop (left) / 3 opp (right).
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const SpeakersSection(),
          ),
        ),
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
    final cubit = context.read<DebateCubit>();
    final localId = cubit.debaterAt(cubit.localSide, 0).id;
    final tiles = <GridParticipant>[
      for (final side in DebateSide.values)
        for (final d in cubit.teamFor(side).debaters)
          GridParticipant(id: d.id, name: d.name, isLocal: d.id == localId),
      for (final a in cubit.data.audience) GridParticipant(id: a.id, name: a.name),
    ];
    return Column(
      children: [
        // TODO(role-gating): "Back to debate" visible only to the judge.
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
      ],
    );
  }
}
