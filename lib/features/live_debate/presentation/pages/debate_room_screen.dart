import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../../data/models/debate_models.dart';
import '../cubits/connection_cubit.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_access.dart';
import '../utils/debate_bell.dart';
import '../utils/debate_theme.dart';
import '../utils/debate_timeline.dart';
import '../widgets/debate_action_row.dart';
import '../widgets/debate_settings_sheet.dart';
import '../widgets/grid_layout.dart';
import '../widgets/main_speaker_card.dart';
import '../widgets/news_ticker.dart';
import '../widgets/poi_widgets.dart';
import '../widgets/speakers_section.dart';
import '../widgets/top_bar_widgets.dart';
import 'result_room_screen.dart';
import '../../../../core/error/failure_text.dart';

/// Layout 2 — the live debate room. Body-only (no AppBar). Connects to
/// LiveKit on init and, for test mode, treats the local user as the first
/// speaker with the timer running immediately.
/// The room's connection lifecycle, used to gate the body so a *failed* connect
/// never silently drops the user into a fake room.
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
    // The system back button must behave EXACTLY like "Leave session":
    // same confirmation dialog, then out to the debate details screen. While
    // not connected (connecting/failed) a plain pop back to the rooms list is
    // kept, matching the failed-view's own leave button.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_phase != _ConnPhase.connected) {
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
          return;
        }
        DebateSettingsSheet.confirmAndLeave(
            context, context.read<DebateController>());
      },
      child: Scaffold(
      backgroundColor: DebateTheme.background(context),
      // The debate layout has no text input of its own (chat is a dialog) —
      // don't let a dialog's soft keyboard reflow/shrink the team cards underneath
      // (that race on dialog-close threw a RenderFlex overflow on some phones).
      resizeToAvoidBottomInset: false,
      body: JadalGradientBackground(
        child: SafeArea(
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
              listener: (context, _) {
                // The asker learns their POI was accepted — push a news line
                // and open the mic dialog (their mic is already lock-exempt).
                context.read<DebateController>().updateLatestNews(context.loc.poiAcceptedNews);
                showDialog(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<DebateController>(),
                    child: const PoiAskerMicDialog(),
                  ),
                );
              },
            ),
            BlocListener<DebateController, DebateStates>(
              listenWhen: (_, s) => s is DebateFinishedState,
              listener: (context, _) => JadalSnackBar.show(
                context,
                context.loc.debateFinished,
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
            // whose back button returns to the live open lobby.
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
            // Chair closed the room → everyone is taken back to the rooms list.
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
                    JadalSnackBar.show(
                      context,
                      FailureText.fromMessage(context, state.message),
                      type: SnackBarType.error,
                    );
                  }
                }
              },
            ),
          ],
          child: Stack(
            children: [
              _gatedBody(context),
              // Chair next-stage guard: a blocking, dimmed loading overlay while the
              // next-stage request is in flight so a double-tap can't skip a speech.
              BlocBuilder<DebateController, DebateStates>(
                buildWhen: (_, s) => s is StageAdvancingChangedState,
                builder: (context, _) {
                  if (!context.read<DebateController>().isAdvancingStage) {
                    return const SizedBox.shrink();
                  }
                  return const Positioned.fill(child: _StageAdvancingOverlay());
                },
              ),
              // "You're talking but muted" — a push-notification-style banner
              // dropping from the top when the voice probe catches the muted
              // speaker/judge. Swipe left/right to dismiss; opening the mic
              // clears it from the cubit side.
              BlocBuilder<DebateController, DebateStates>(
                buildWhen: (_, s) =>
                    s is MutedSpeakingChangedState ||
                    s is MicToggledState ||
                    s is PublishLockChangedState,
                builder: (context, _) {
                  final cubit = context.read<DebateController>();
                  return Positioned(
                    top: 6,
                    left: 12,
                    right: 12,
                    child: _MutedSpeakingBanner(
                      visible: cubit.mutedSpeakingActive,
                      canUnmute: cubit.canPublishNow,
                      onUnmute: cubit.toggleMic,
                      onDismissed: cubit.dismissMutedSpeakingBanner,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        ),
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
    return BlocBuilder<ConnectionCubit, ConnectionStates>(
      builder: (context, _) {
        final connection = context.read<ConnectionCubit>();
        // A guest has no action row, so the animation stays collapsed and the
        // cards keep the space the bar would have taken.
        final showActions = !cubit.isGuest && connection.showActions;
        // A single animated driver: t = 1 → tool bar fully shown, 0 → hidden.
        // The action row's height is `t·kHeight` and the cards' freed space is
        // `(1-t)·kHeight`, so they sum to kHeight at every frame — the cards
        // shrink *exactly* as fast as the bar grows into their place (no snap,
        // no overflow).
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: showActions ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) {
            return Column(
              children: [
                // (A) Top row: audience button | news ticker | motion button.
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
                // (B)+(C) Main speaker card + speakers. The freed space is
                // redistributed 75% to the main card / 25% to the team cards
                // so the team cards barely shrink and never overflow.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      const gaps = 16.0 + 8.0;
                      final freed = (1 - t) * DebateActionRow.kHeight;
                      final base =
                          (c.maxHeight - freed - gaps).clamp(0.0, double.infinity);
                      final mainH = base * 0.40 + freed * 0.75;
                      final speakersH = base * 0.60 + freed * 0.25;
                      // The main card's slot is taller than its artwork by the
                      // timer button's overhang (the button must stay inside a
                      // hit-testable box). That extra height is taken back out
                      // of the 16dp gap first and only then out of the speakers
                      // area, so the card renders at `mainH` exactly as before
                      // and the column's total height is unchanged.
                      const gap = 16.0;
                      const overhang = kMainSpeakerBottomOverhang;
                      final gapAfterMain = (gap - overhang).clamp(0.0, gap);
                      final speakersAdjusted =
                          speakersH - (overhang - gap).clamp(0.0, overhang);
                      return Column(
                        children: [
                          SizedBox(
                            height: mainH + overhang,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: MainSpeakerCard(),
                            ),
                          ),
                          SizedBox(height: gapAfterMain),
                          SizedBox(
                            height: speakersAdjusted,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: SpeakersSection(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
                // (D) The bottom action row, revealed top-down in lockstep with
                // t. Guests have no controls at all, so the row is not built.
                if (!cubit.isGuest)
                  GestureDetector(
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
              ],
            );
          },
        );
      },
    );
  }
}

/// Open-lobby mode: everyone in the grid; a judge-only "Back to debate"
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
      // Judges pinned to the top, then prop / opp / audience.
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
    // Append anyone *present in the room* who isn't on the roster (a plain
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
    // The loop above only walks REMOTE participants, so an off-roster LOCAL
    // viewer never saw their own tile (their friends did, via the remote pass).
    // Give the local user a tile too when the roster missed them.
    final meId = cubit.data.currentUserId;
    if (meId.isNotEmpty && !shownIds.contains(meId)) {
      tiles.add(GridParticipant(
        id: meId,
        name: cubit.localParticipant?.name.isNotEmpty == true
            ? cubit.localParticipant!.name
            : loc.youTag,
        isLocal: true,
      ));
    }
    return Column(
      children: [
        // "Back to debate" is chair-only — and gone once the result phase opens
        // (speeches done / revealed / completed): the room then stays in the open
        // lobby and can't return to a speech.
        if (cubit.canControlStage && !cubit.resultPhaseOpen)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => cubit.setLobbyMode(false),
                // Pre-live this enters the intro (chair welcome); mid-debate
                // it resumes the paused speaker.
                icon: Icon(cubit.debateStarted
                    ? Icons.arrow_back_rounded
                    : Icons.play_arrow_rounded),
                label: Text(cubit.debateStarted ? loc.backToDebate : loc.goLiveSession),
              ),
            ),
          ),
        Expanded(child: GridLayout(participants: tiles)),
        // Auto-hiding action row, toggled by the screen's outer tap. Guests
        // have no controls, so it is left out entirely.
        if (!cubit.isGuest)
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

/// The push-notification-style banner shown when the local muted speaker/judge
/// is caught talking: slides down from the top, offers a one-tap unmute, and is
/// swipe-dismissible left/right.
class _MutedSpeakingBanner extends StatelessWidget {
  final bool visible;
  final bool canUnmute;
  final VoidCallback onUnmute;
  final VoidCallback onDismissed;
  const _MutedSpeakingBanner({
    required this.visible,
    required this.canUnmute,
    required this.onUnmute,
    required this.onDismissed,
  });

  static const _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.6),
          end: Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: !visible
          ? const SizedBox.shrink()
          : Dismissible(
              key: const ValueKey('muted-speaking-banner'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => onDismissed(),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: DebateTheme.surfaceElevated(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _red.withValues(alpha: 0.55), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _red.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.mic_off_rounded, color: _red, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.mutedSpeakingTitle,
                              style: AppTextStyles.bodyEmphasis(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: DebateTheme.textPrimary(context)),
                            ),
                            Text(
                              loc.mutedSpeakingBody,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(context).copyWith(
                                  height: 1.25, color: DebateTheme.textSecondary(context)),
                            ),
                          ],
                        ),
                      ),
                      if (canUnmute) ...[
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: onUnmute,
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(
                            loc.unmuteAction,
                            style: AppTextStyles.caption(context)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// A dimmed, tap-absorbing overlay with a centred spinner shown while the chair's
/// next-stage request is in flight — prevents a double-tap skipping a speech.
class _StageAdvancingOverlay extends StatelessWidget {
  const _StageAdvancingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // A modal barrier: absorbs taps so the next-stage control can't be hit again.
      color: Colors.black.withValues(alpha: 0.35),
      child: const Center(
        child: SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
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
              style: AppTextStyles.subtitle(context)
                  .copyWith(fontWeight: FontWeight.w600, color: DebateTheme.textSecondary(context)),
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
              style: AppTextStyles.title(context)
                  .copyWith(color: DebateTheme.textPrimary(context)),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                // Was the raw failure string — a LiveKit/socket exception is
                // meaningless to a debater waiting to join.
                FailureText.fromMessage(context, message),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context)
                    .copyWith(color: DebateTheme.textSecondary(context)),
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
