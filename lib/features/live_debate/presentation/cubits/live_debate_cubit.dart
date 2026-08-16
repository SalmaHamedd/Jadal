import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:livekit_client/livekit_client.dart';

import '../../../../core/error/failures.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/datasources/backend_live_debate_data.dart';
import '../../data/live_debate_socket_events.dart';
import '../../data/models/debate_models.dart';
import '../../data/models/debate_result_model.dart';
import '../../data/models/live_state_model.dart';
import '../../data/repositories/live_debate_repository.dart';
import '../../domain/debate_result_view.dart';
import '../../domain/debate_room_role.dart';
import '../../domain/live_debate_data.dart';
import '../utils/debate_log.dart';
import '../utils/debate_timeline.dart';
import 'debate_controller.dart';

/// Backend-connected live-debate controller. REST drives actions; the
/// LiveKit data channel drives state via the `{"event": …}` codec
/// ([LiveDebateSocket]). The **chair** is the timer authority and broadcasts the
/// timer every second; non-chairs keep a local timer and reconcile within
/// [kTimerSyncOffsetSeconds]. Implements [DebateController] so the shared widget
/// tree renders it identically to the mock (the only difference is role-gating).
class LiveDebateCubit extends DebateController {
  LiveDebateCubit({
    required this.repo,
    required this.profileRepo,
    required this.debateId,
    this.asGuest = false,
  })  : _data = BackendLiveDebateData.empty(),
        super(DebateInitialState()) {
    _timeline = DebateTimeline(_data.format);
    if (asGuest) _role = DebateRoomRole.guest;
  }

  final LiveDebateRepository repo;
  final ProfileRepository profileRepo;
  final int debateId;

  /// Watching through a share link with no account. Everything that needs a
  /// user — profile, chat, publishing, moderation — is skipped.
  final bool asGuest;

  // ── State ──────────────────────────────────────────────────────────────────
  LiveStateModel? _state;
  BackendLiveDebateData _data;
  int _myUserId = 0;
  DebateRoomRole _role = DebateRoomRole.unknown;
  int? _electedChairUserId;
  bool _isReady = false;
  Failure? _loadFailure;

  @override
  Failure? get loadFailure => _loadFailure;

  /// Tracks authority so a non-authority→authority transition (a chair
  /// hand-off picked up by live-state / the poll, without a rejoin) can
  /// re-broadcast the current publish-lock so everyone converges on the new chair.
  bool _wasAuthority = false;

  @override
  LiveDebateData get data => _data;

  @override
  bool get isReady => _isReady;

  late DebateTimeline _timeline;
  @override
  DebateTimeline get timeline => _timeline;

  // ── LiveKit ──────────────────────────────────────────────────────────────────
  Room? _room;
  EventsListener<RoomEvent>? _roomEvents;
  @override
  ConnectionQuality connectionQuality = ConnectionQuality.unknown;
  @override
  LocalParticipant? localParticipant;
  @override
  List<RemoteParticipant> participants = [];
  final Map<String, bool> _remoteHasAudio = {};
  final Map<String, bool> _remoteHasVideo = {};
  final Map<String, bool> _remoteSpeaking = {};
  @override
  LocalVideoTrack? localVideoTrack;
  LocalAudioTrack? localAudioTrack;
  @override
  bool isLocalSpeaking = false;
  @override
  bool isMicEnabled = false;
  @override
  bool isCameraEnabled = false;
  Timer? _connectionQualityTimer;

  /// Periodic `live-state` re-fetch. Self-heals a missed `chair_elected`
  /// and a dropped participant join/leave — the screen rebuilds into the
  /// correct state without anyone leaving — and (with the new logging) prints the
  /// fresh backend payload + digest every tick so issues are diagnosable live.
  Timer? _pollTimer;
  // Tightened from 10s → 5s so a missed broadcast (stage/timer/presence) is
  // reconciled about twice as fast. The real "wrong timer for a few seconds after
  // next-stage" fix is refreshing live-state right on `stage_changed` (below); the
  // poll is just the safety net, so this stays moderate to avoid extra load.
  static const Duration kLiveStatePollInterval = Duration(seconds: 5);
  int _pollCount = 0;

  @override
  double get localAudioLevel => _room?.localParticipant?.audioLevel ?? 0;

  // ── Timer ────────────────────────────────────────────────────────────────────
  @override
  int elapsedSeconds = 0;
  @override
  bool isPaused = true;
  Timer? _localTimer;

  /// The user's **functional debate role**, derived from the live-state (the
  /// source of truth) rather than the LiveKit token's `role_in_room`.
  /// This is the core fix for "I joined as the chair but the UI treats me as a
  /// viewer": the main-room token returns `role_if_joined: "viewer"` for judges
  /// and debaters alike (it only controls LiveKit publish rights), so the token
  /// role can never tell us the user is a chair/judge/debater. The live-state
  /// can — `judges[].is_chair`, the judge panel, and the speaker lists — so we
  /// resolve the role from there and fall back to the token role only for
  /// genuine viewers/trainers.
  DebateRoomRole get _debateRole {
    final s = _state;
    if (s != null) {
      if (s.isChair(_myUserId) || _electedChairUserId == _myUserId) {
        return DebateRoomRole.judgeChair;
      }
      if (s.isJudge(_myUserId)) return DebateRoomRole.judgePanel;
      if (s.speakerByUserId(_myUserId) != null) return DebateRoomRole.debater;
    } else if (_electedChairUserId == _myUserId) {
      return DebateRoomRole.judgeChair;
    }
    return _role; // trainer / viewer / unknown from the token
  }

  /// The chair is the timer/flow authority. Trusts the live-state chair
  /// (resilient to a missed `chair_elected` broadcast for late joiners) on top
  /// of the token role + the in-memory elected flag.
  @override
  bool get isAuthority => _debateRole.isChair;

  // ── Stage flow ────────────────────────────────────────────────────────────────
  int _currentStage = 0; // 0 = lobby
  int? _currentSpeakerUserId;
  DateTime? _serverStartedAt;

  // ── Orders / POI / chat / news ────────────────────────────────────────────────
  @override
  late SpeakerOrder propOrder = const SpeakerOrder();
  @override
  late SpeakerOrder oppOrder = const SpeakerOrder();
  final Set<int> _poiRaisedUserIds = {};
  @override
  bool isLocalAskingPOI = false;
  @override
  bool localPoiAccepted = false;
  Timer? _poiTimer;
  @override
  String latestNews = '';
  int _newsCounter = 1;
  final List<TeamChatMessage> _chat = [];
  @override
  List<TeamChatMessage> get chatMessages => List.unmodifiable(_chat);

  // ── Moderation publish-lock (mic + camera) + close-room ────
  bool _muteAllActive = false;
  bool _cameraAllOff = false;
  final Set<String> _micLockedIds = {};
  final Set<String> _cameraLockedIds = {};
  bool _roomClosed = false;

  // ── Muted-but-speaking detection ─────────────────────────────────────────────
  // While the local user is the main speaker or a judge WITH their mic off, an
  // unpublished probe audio track + the LiveKit visualizer watch the real mic
  // level; sustained voice above the threshold flips [mutedSpeakingActive] and
  // the room shows the top banner. Nothing is ever published from the probe.
  LocalAudioTrack? _mutedVoiceTrack;
  AudioVisualizer? _mutedVoiceVisualizer;
  EventsListener<AudioVisualizerEvent>? _mutedVoiceListener;
  bool _mutedSpeakingDetected = false;
  bool _mutedBannerDismissed = false;
  bool _mutedMonitorStarting = false;

  /// Learned quiet level, and when the current above-threshold run began.
  double _mutedVoiceFloor = 0;
  DateTime? _mutedVoiceLoudSince;

  /// Diagnostics: proves whether the native visualizer is actually feeding us
  /// (see [_mutedVoiceWatchdog]) and throttles the level trace.
  Timer? _mutedVoiceWatchdog;
  int _mutedVoiceEvents = 0;
  DateTime? _mutedVoiceLastTrace;

  /// Detection uses the loudest band, not the mean of all bands: speech only
  /// lights up two or three of the seven, so the mean stays near zero even
  /// when someone is talking loudly.
  ///
  /// Absolute levels swing with mic gain and how close the phone is, so the
  /// trigger is [_mutedVoiceFloor] (a slowly-learned quiet level) plus
  /// [kMutedVoiceMargin], never below [kMutedVoiceMinPeak].
  static const double kMutedVoiceMinPeak = 0.035;
  static const double kMutedVoiceMargin = 0.03;

  /// How fast the quiet level adapts. Only updated while BELOW the trigger, so
  /// speech can never inflate the floor and mute the detector.
  static const double kMutedVoiceFloorAlpha = 0.02;

  /// Sustained speech required before the banner shows (debounces coughs and
  /// desk bumps). Time-based, not a frame count: the native side emits ~100
  /// windows/sec, so the old "3 windows" was ~30 ms.
  static const Duration kMutedVoiceHold = Duration(milliseconds: 400);

  /// If the native visualizer never delivers a window this long after start,
  /// the probe pipeline itself is broken (rather than merely quiet) — log it
  /// loudly instead of failing silently.
  static const Duration kMutedVoiceWatchdog = Duration(seconds: 3);

  /// Whether the chat dialog is currently open — an incoming message is
  /// marked seen immediately while true; [unreadTeamChatCount] is derived
  /// from each message's `seenBy`, not tracked as a separate counter.
  bool _chatOpen = false;

  /// The chair's next-stage POST is in flight → the room shows a blocking overlay
  /// so a double-tap can't skip a speech.
  bool _advancingStage = false;

  /// Emit the "go to the shared result" navigation exactly once,
  /// whether it's triggered by the chair sharing or by the inbound
  /// `result_revealed` broadcast (the chair receives its own broadcast too).
  bool _resultNavSignaled = false;

  /// Chair-driven open-lobby PAUSE overlay: a break that freezes the
  /// current speaker + timer where they are (so it resumes from the same spot)
  /// WITHOUT advancing/rolling-back the backend stage. Distinct from the real
  /// stage-0 lobby (`_currentStage <= 0`).
  bool _lobbyOverlay = false;

  // ──────────────────────────────────────────────────────────────────────────
  // Load
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> init() async {
    dlog('init', 'starting init for debateId=$debateId (asGuest=$asGuest)');
    emit(DebateConnectingState());
    if (asGuest) {
      // No token, so there is no profile to resolve and no team chat to load.
      // Both of those calls would 401 and bounce us to the login screen.
      await _refreshLiveState();
      if (_loadFailure != null) {
        dlog('init', 'guest init aborted: ${_loadFailure!.message}');
        return;
      }
      _startLiveStatePolling();
      _isReady = true;
      dlog('init', 'guest init complete — isReady=true');
      emit(DebateConnectedState());
      return;
    }
    final profile = await profileRepo.getProfile();
    profile.fold(
      (f) => dlog('init', 'WARN could not load profile: ${f.message} '
          '(myUserId stays $_myUserId)'),
      (p) {
        _myUserId = p.id;
        dlog('init', 'resolved myUserId=$_myUserId (${p.name})');
      },
    );
    await _refreshLiveState();
    await _loadChatHistory();
    _startLiveStatePolling();
    _isReady = true;
    dlog('init', 'init complete — isReady=true');
    emit(DebateConnectedState());
  }

  /// Seeds `_chat` from the persisted history so a rejoining participant
  /// sees the full team conversation instead of starting empty. Best-effort —
  /// a failure here just leaves chat empty for this session, same as before.
  Future<void> _loadChatHistory() async {
    final res = await repo.getChatHistory(debateId);
    res.fold(
      (f) => dlog('chat', 'WARN could not load chat history: ${f.message}'),
      (messages) {
        final teamId = myTeamId;
        if (teamId.isEmpty) return; // judge/viewer/trainer — no team chat
        _chat.addAll(messages.map((m) => TeamChatMessage(
              id: m.id,
              teamId: teamId,
              senderId: m.senderId,
              senderName: m.senderName,
              message: m.message,
              ts: m.sentAt.millisecondsSinceEpoch,
              seenBy: m.seenBy,
            )));
        dlog('chat', 'loaded ${messages.length} chat message(s) for team=$teamId');
      },
    );
  }

  Future<void> _refreshLiveState() async {
    dlog('live-state', 'fetching live-state for debateId=$debateId');
    final res = await repo.getLiveState(debateId);
    res.fold(
      (f) {
        dlog('live-state', 'FETCH FAILED: ${f.message}');
        _loadFailure = f;
        // A guest's viewing window closes ten minutes after the debate ends.
        // Once that happens every poll would fail, so stop polling instead of
        // raising the same error every few seconds.
        if (asGuest && f is GoneFailure) _stopLiveStatePolling();
        emit(DebateErrorState(f.message));
      },
      (s) {
        _loadFailure = null;
        _applyLiveState(s);
      },
    );
  }

  /// Start the ~10s live-state poll. Idempotent; runs for the whole
  /// session (lobby → live → result) and is cancelled on leave/close. Each tick
  /// logs a banner then re-fetches, so the trace shows the backend's answer at
  /// that moment (the "show me the data fetched every 10s" requirement).
  void _startLiveStatePolling() {
    _pollTimer?.cancel();
    dlog('poll', 'starting periodic live-state poll every '
        '${kLiveStatePollInterval.inSeconds}s');
    _pollTimer = Timer.periodic(kLiveStatePollInterval, (_) {
      if (isClosed) return;
      _pollCount++;
      dlog('poll', '⟳ poll #$_pollCount — re-fetching live-state '
          '(currentStage=$_currentStage, derivedRole=${_debateRole.wire})');
      _refreshLiveState();
    });
  }

  void _stopLiveStatePolling() {
    if (_pollTimer != null) dlog('poll', 'stopping periodic live-state poll');
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _applyLiveState(LiveStateModel s) {
    final prevStage = _currentStage;
    _state = s;
    _data = BackendLiveDebateData(s, _myUserId);
    _currentStage = s.debate.currentStage;
    _seedOrders();
    final stageEntry = _stageByOrder(_currentStage);
    _rebuildTimeline(stageEntry?.durationSeconds);

    // Resolve the current speaker straight from live-state — the chair
    // never receives its own `stage_changed`, so this is its only way to know who
    // holds the floor. Prefer the server-resolved `speaker_user_id`, falling
    // back to the participant→user mapping.
    _currentSpeakerUserId = _currentStage <= 0
        ? null
        : (stageEntry?.speakerUserId ??
            s.speakerByParticipantId(stageEntry?.participantId)?.user.id);
    _serverStartedAt = s.debate.currentStageStartedAt?.toUtc();

    final stageChanged = prevStage != _currentStage;

    // The timer is SERVER-authoritative. Every client (not just the chair)
    // computes elapsed from the server clock + the persisted paused state, so all
    // devices agree and a (re)joiner restores the exact clock — including a paused
    // open-lobby break (Issues 6 & 7). No peer `time_update` dependency anymore.
    _applyServerTimer(
      stageStartedAt: _serverStartedAt,
      serverNow: s.debate.serverNow?.toUtc(),
      paused: s.debate.timerIsPaused,
      pausedElapsed: s.debate.timerPausedElapsedSeconds,
    );

    if (stageChanged) {
      _clearPois(); // Leftover POIs don't survive into the next speech
      // Flip the lobby↔debate gate (the chair's own action has no broadcast).
      emit(LobbyModeChangedState());
      emit(SpeakerChangedState());
      if (_currentStage > 0) {
        emit(DebateTimelineEventState(DebateTimelineEvent.speechStarted));
      }
    }
    _logLiveStateDigest(s);
    _logRoleResolution('live-state applied');
    _maybeAnnounceAuthorityGain();
    // Media rights depend on the stage/format (live debate is audio-only): the
    // moment this device loses a right its own track goes off — e.g. the chair's
    // intro camera the instant the first speaker starts. Also re-decide whether
    // the muted-voice probe should run (the floor / judge role may have moved).
    _enforcePublishLock();
    _syncMutedVoiceMonitor();
    if (s.debate.isCompleted) emit(DebateFinishedState());
    emit(LiveStateUpdatedState());
  }

  /// When this device transitions to chair (re-derived from a fresh
  /// live-state / the poll — no rejoin needed), re-broadcast the current
  /// publish-lock so everyone converges on the new chair's view, and trace it so
  /// the next test shows exactly when control changed hands.
  void _maybeAnnounceAuthorityGain() {
    final now = isAuthority;
    if (now != _wasAuthority) {
      dlog('role', 'AUTHORITY ${now ? "GAINED" : "LOST"} — '
          'this device is ${now ? "now" : "no longer"} the chair');
      if (now) _broadcastPublishLock(); // converge everyone on the new chair's locks
    }
    _wasAuthority = now;
  }

  /// Human-readable summary of the *interpreted* live-state, printed on every
  /// apply (incl. each 10s poll). This is the answer to "is the bug mine or the
  /// backend's?": the raw body is already in the `http` trace; this shows how we
  /// read it — who the backend says is chair, the judge order, who's attended,
  /// the speaking order, and the current stage. If the wrong (lower-order) judge
  /// holds `is_chair`, it shows here straight from the backend's own fields.
  void _logLiveStateDigest(LiveStateModel s) {
    final b = StringBuffer();
    final d = s.debate;
    b.writeln('── live-state digest (debateId=$debateId, me=$_myUserId) ──');
    b.writeln('debate: status=${d.statusRaw} currentStage=${d.currentStage} '
        'stageStartedAt=${d.currentStageStartedAt?.toIso8601String()} '
        'resultRevealedAt=${d.resultRevealedAt?.toIso8601String()} '
        'cancellationReason=${d.cancellationReason}');
    String room(String n, RoomEntry r) =>
        '$n{open=${r.open}, joinableForMe=${r.joinableForMe}, role=${r.roleIfJoined?.wire}}';
    b.writeln('rooms: ${room("main", s.rooms.main)} ${room("prop", s.rooms.prop)} '
        '${room("opp", s.rooms.opp)} ${room("result", s.rooms.result)}');
    final judges = [...s.judges]
      ..sort((a, c) => (a.judgeOrder ?? 1 << 30).compareTo(c.judgeOrder ?? 1 << 30));
    b.writeln('judges (${judges.length}) — order/id/name/is_chair/is_attended:');
    for (final j in judges) {
      b.writeln('   • order=${j.judgeOrder} userId=${j.user.id} "${j.user.name}" '
          'is_chair=${j.isChair} is_attended=${j.isAttended}'
          '${j.user.id == _myUserId ? "   ← me" : ""}');
    }
    final chair = s.chairJudge;
    b.writeln('   → backend chairJudge = ${chair == null ? "NONE" : 'order=${chair.judgeOrder} '
        'userId=${chair.user.id} "${chair.user.name}"'}');
    void side(String tag, SideInfo si) {
      b.writeln('$tag: team=${si.team?.name ?? "(none)"} isRandom=${si.isRandom} '
          'members=${si.members.length} speakers=${si.speakers.length} '
          'speaking_order(userIds)=${si.speakingOrderUserIds}');
      for (final sp in si.orderedSpeakers) {
        b.writeln('   • phase=${sp.speakingPhaseOrder} userId=${sp.user.id} '
            '"${sp.user.name}" side=${sp.side} status=${sp.status} '
            'is_attended=${sp.isAttended} is_reply=${sp.isReplySpeaker}');
      }
    }

    side('prop', s.proposition);
    side('opp', s.opposition);
    b.writeln('stages (${s.stages.length}) — order/name/status/speaker_user_id/phaseId:');
    for (final st in s.stages) {
      b.writeln('   • #${st.orderIndex} "${st.name}" status=${st.status} '
          'speakerUserId=${st.speakerUserId} participantId=${st.participantId} '
          'phaseId=${st.id} isReply=${st.isReply}');
    }
    final r = s.result;
    b.write('result: ${r == null ? "null (none/not revealed for me)" : 'winner=${r.winningSide} '
        'scoredStages=${r.stageScores.length}'}');
    dlog('digest', b.toString());
  }

  /// Single place that explains *why* the local user has the role/authority it
  /// does — the answer to "why am I treated as a viewer?". Cross-references the
  /// token room role against the live-state source of truth.
  void _logRoleResolution(String when) {
    final s = _state;
    final chair = s?.chairJudge;
    dlog(
      'role',
      '[$when] myUserId=$_myUserId | tokenRoomRole=${_role.wire} | '
          'derivedRole=${_debateRole.wire} | isAuthority=$isAuthority | '
          'isSpectator=$isSpectator | '
          'liveState.isChair=${s?.isChair(_myUserId)} | '
          'liveState.isJudge=${s?.isJudge(_myUserId)} | '
          'isSpeaker=${s?.speakerByUserId(_myUserId) != null} | '
          'electedChairUserId=$_electedChairUserId | '
          'chairJudge=${chair?.user.id}/${chair?.user.name} | '
          'currentStage=$_currentStage',
    );
  }

  void _seedOrders() {
    final st = _state;
    if (st == null) return;
    propOrder = SpeakerOrder(
      orderedSpeakerIds: _data.propositionTeam.debaters.map((d) => d.id).toList(),
      replySpeakerId: st.proposition.replySpeaker?.user.id.toString(),
      isSet: st.proposition.speakers.isNotEmpty,
    );
    oppOrder = SpeakerOrder(
      orderedSpeakerIds: _data.oppositionTeam.debaters.map((d) => d.id).toList(),
      replySpeakerId: st.opposition.replySpeaker?.user.id.toString(),
      isSet: st.opposition.speakers.isNotEmpty,
    );
  }

  StageEntry? _stageByOrder(int order) {
    for (final s in _state?.stages ?? const <StageEntry>[]) {
      if (s.orderIndex == order) return s;
    }
    return null;
  }

  void _rebuildTimeline(int? durationSeconds) {
    final base = _data.format;
    _timeline = DebateTimeline(DebateFormat(
      preparationPeriod: base.preparationPeriod,
      speechDuration: Duration(seconds: durationSeconds ?? base.speechDuration.inSeconds),
      protectedPeriod: base.protectedPeriod,
      extraTime: base.extraTime,
      replySpeech: base.replySpeech,
      replyDuration: base.replyDuration,
    ));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Rooms / connection (token discipline)
  // ──────────────────────────────────────────────────────────────────────────

  String _roomParam(DebateRoomType type) => switch (type) {
    DebateRoomType.proposition => 'prop',
    DebateRoomType.opposition => 'opp',
    DebateRoomType.liveDebate => 'main',
    DebateRoomType.result => 'result',
  };

  @override
  ({bool joinable, DebateRoomRole? role})? backendRoomGate(DebateRoomType type) {
    final rooms = _state?.rooms;
    if (rooms == null) return (joinable: false, role: null);
    final r = switch (type) {
      DebateRoomType.proposition => rooms.prop,
      DebateRoomType.opposition => rooms.opp,
      DebateRoomType.liveDebate => rooms.main,
      DebateRoomType.result => rooms.result,
    };
    return (joinable: r.joinableForMe, role: r.roleIfJoined);
  }

  @override
  Future<void> joinRoom(DebateRoomType type) async {
    final roomParam = _roomParam(type);
    dlog('join', 'requesting room token for "$roomParam" (debateId=$debateId)');
    final res = await repo.getRoomToken(debateId, roomParam);
    await res.fold(
      (f) async {
        dlog('join', 'TOKEN REQUEST FAILED for "$roomParam": ${f.message}');
        emit(DebateErrorState(f.message));
      },
      (t) async {
        _role = t.roleInRoom;
        dlog(
          'join',
          'token received for "$roomParam" | tokenRoomRole=${t.roleInRoom.wire} '
              '| url=${t.url.isEmpty ? "<empty>" : t.url} | tokenLen=${t.token.length}',
        );
        // Validation gate: never connect with an unusable token. This is exactly
        // what used to let a *failed* connect still drop the user into the room.
        if (t.url.trim().isEmpty || t.token.trim().isEmpty) {
          dlog('join', 'ABORT: token/url missing — refusing to connect');
          emit(DebateErrorState('Invalid room token from server (missing url/token).'));
          return;
        }
        _logRoleResolution('after token for "$roomParam"');
        await connectToRoom(url: t.url, token: t.token);
      },
    );
  }

  /// Backend room entry: fetch a fresh main-room token, connect, then listen.
  /// The chair waits for the next-stage button; everyone else for `stage_changed`.
  @override
  Future<void> enterDebateRoom() async {
    dlog('enter', 'ENTER debate room (debateId=$debateId, myUserId=$_myUserId)');
    await joinRoom(DebateRoomType.liveDebate);
  }

  @override
  Future<void> connectToRoom({required String url, required String token}) async {
    emit(DebateConnectingState());

    try {
      await _room?.disconnect();
      await _roomEvents?.dispose();

      _room = Room(roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
      _roomEvents = _room!.createListener();
      _registerRoomListeners();

      dlog('connect', 'ATTEMPTING connect to $url');
      await _room!.connect(url, token);
      final sid = await _room!.getSid();
      final identity = _room!.localParticipant?.identity;
      dlog(
        'connect',
        'CONNECT SUCCEEDED — room.sid=$sid | localIdentity=$identity | '
            'localSid=${_room!.localParticipant?.sid} | '
            'remoteParticipants=${_room!.remoteParticipants.length} '
            '[${_room!.remoteParticipants.values.map((p) => p.identity).join(", ")}]',
      );
      // Integrity check: the LiveKit identity must match the auth user we
      // resolved from the profile, or presence and role lookups (which key off
      // the user id) silently fail. Guests are exempt — theirs is a synthetic
      // `guest-<uuid>` that intentionally matches no user.
      if (!asGuest && identity != null && identity != _myUserId.toString()) {
        dlog(
          'connect',
          'WARN identity mismatch: LiveKit identity="$identity" but myUserId=$_myUserId '
              '— presence-by-userId may be off',
        );
      }

      localParticipant = _room!.localParticipant;
      // A guest's token carries no publish rights, so don't touch the devices
      // at all — asking for them would prompt for permissions the guest can
      // never use.
      if (!asGuest) {
        await localParticipant?.setCameraEnabled(false);
        await localParticipant?.setMicrophoneEnabled(false);
      }
      _startConnectionQualityTimer();
      _refreshParticipants();
      emit(DebateConnectedState());
      emit(LocalTrackUpdatedState());
      // The backend may elect/assign the chair as a side effect of the judge
      // JOINING the main room — which happens after our pre-join init snapshot.
      // Re-sync once connected so a sole/late judge gains chair authority even if
      // the chair_elected broadcast never arrives. (If live-state still reports
      // no chair, the gap is server-side: nobody was elected.)
      dlog('connect', 're-fetching live-state post-connect to catch join-time chair election');
      await _refreshLiveState();
      _logRoleResolution('post-connect refresh');
    } catch (e, stack) {
      dlog('connect', 'CONNECT FAILED: $e');
      dlog('connect', stack.toString());
      emit(DebateErrorState('Failed to connect: $e'));
    }
  }


  void _startConnectionQualityTimer() {
    _connectionQualityTimer?.cancel();
    _connectionQualityTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isClosed) return;
      connectionQuality =
          _room?.localParticipant?.connectionQuality ?? ConnectionQuality.unknown;
      emit(LocalTrackUpdatedState());
    });
  }

  LocalVideoTrack? _localVideoTrack() =>
      _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
  LocalAudioTrack? _localAudioTrack() =>
      _room?.localParticipant?.audioTrackPublications.firstOrNull?.track;

  bool _remoteMicOn(RemoteParticipant p) {
    final pub = p.getTrackPublicationBySource(TrackSource.microphone);
    return pub != null && pub.track != null && pub.track?.muted == false;
  }

  bool _remoteCameraOn(RemoteParticipant p) {
    final pub = p.getTrackPublicationBySource(TrackSource.camera);
    return pub != null && pub.track != null && pub.track?.muted == false;
  }

  void _registerRoomListeners() {
    if (_roomEvents == null || _room == null) return;
    _roomEvents!
      ..on<LocalTrackPublishedEvent>((_) {
        _refreshParticipants();
        emit(LocalTrackUpdatedState());
      })
      ..on<LocalTrackUnpublishedEvent>((event) {
        if (event.publication.track is LocalVideoTrack) {
          localVideoTrack = null;
          emit(LocalTrackUpdatedState());
        }
      })
      ..on<TrackSubscribedEvent>((_) => _refreshParticipants())
      ..on<TrackUnsubscribedEvent>((_) => _refreshParticipants())
      // A remote mic/camera mute or unmute must refresh the cached
      // audio/video flags, else the tile shows a frozen frame / "not speaking"
      // instead of clearly muted / camera-off.
      ..on<TrackMutedEvent>((_) => _refreshParticipants())
      ..on<TrackUnmutedEvent>((_) => _refreshParticipants())
      // Dedicated join/leave trace (identity + new count) so a multi-device
      // test can confirm the event even fires on the other device.
      ..on<ParticipantConnectedEvent>((event) {
        dlog('presence', 'JOIN ▸ ${event.participant.identity} '
            '(${event.participant.name}) — now ${_room!.remoteParticipants.length + 1} in room');
        _refreshParticipants();
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        dlog('presence', 'LEAVE ▸ ${event.participant.identity} '
            '(${event.participant.name}) — now ${_room!.remoteParticipants.length + 1} in room');
        _refreshParticipants();
      })
    // Correct speaking detection for local + remote.
      ..on<ActiveSpeakersChangedEvent>((event) {
        final speakerSids = event.speakers.map((s) => s.sid).toSet();
        isLocalSpeaking = localParticipant != null &&
            speakerSids.contains(localParticipant!.sid);
        for (final p in participants) {
          _remoteSpeaking[p.sid] = speakerSids.contains(p.sid);
        }
        if (!isClosed) emit(RemoteTrackReceivedState());
      })
      ..on<RoomDisconnectedEvent>((event) {
        // An intentional leave already handles its own navigation;
        // only unexpected disconnects notify the room screen.
        if (_userLeaving || isClosed) return;
        emit(DebateDisconnectedState(reason: event.reason.toString()));
      })
      ..on<DataReceivedEvent>((event) => _onData(event.data));
  }

  void _refreshParticipants() {
    if (_room == null) return;
    localParticipant = _room!.localParticipant;
    localVideoTrack = _localVideoTrack();
    localAudioTrack = _localAudioTrack();
    final tmp = <RemoteParticipant>[];
    for (final p in _room!.remoteParticipants.values) {
      tmp.add(p);
      _remoteHasAudio[p.sid] = _remoteMicOn(p);
      _remoteHasVideo[p.sid] = _remoteCameraOn(p);
    }
    participants = tmp;
    dlog(
      'presence',
      'room now has ${tmp.length} remote + 1 local | '
          'present userIds=[${[
        _myUserId.toString(),
        ...tmp.map((p) => p.identity)
      ].join(", ")}]',
    );
    emit(RemoteTrackReceivedState());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Incoming backend events
  // ──────────────────────────────────────────────────────────────────────────

  void _onData(List<int> bytes) {
    final event = LiveDebateSocket.decode(bytes);
    if (event == null) {
      dlog('socket-recv', 'received UNDECODABLE data-channel message (${bytes.length} bytes)');
      return;
    }
    // Show the FULL inbound payload so the trace explains exactly what each event
    // carried — skip only the chair's per-second `time_update` (pure timer noise).
    if (event.type != LiveEventType.timeUpdate) {
      dlogJson('socket-recv', 'event=${event.type.wire}', event.data);
    }
    switch (event.type) {
      case LiveEventType.stageChanged:
        _onStageChanged(event);
        break;
      case LiveEventType.debateModeStarted:
        // The chair started the live session (intro) OR a real lobby→debate
        // move. Refresh to pick up `live_started_at` so this device shows the
        // intro (chair welcome) vs the open lobby correctly.
        dlog('mode', 'debate_mode_started → live session started (intro)');
        _refreshLiveState();
        emit(LobbyModeChangedState());
        break;
      case LiveEventType.returnedToLobby:
        dlog('mode', 'returned_to_lobby → back to the open lobby (stage 0)');
        _currentStage = 0;
        _resetTimerSilently();
        _refreshLiveState();
        emit(LobbyModeChangedState());
        break;
      case LiveEventType.participantAttended:
        emit(RemoteTrackReceivedState());
        break;
      case LiveEventType.chairElected:
        dlog('data', 'chair_elected → chairUserId=${event.chairUserId} '
            '(me=$_myUserId) — refreshing live-state to resync is_chair');
        _electedChairUserId = event.chairUserId;
        // Resync judges[].is_chair from the source of truth — a late joiner can
        // miss this fire-and-forget broadcast, so re-fetch instead of trusting
        // only the in-memory flag + a possibly-stale token role.
        _refreshLiveState();
        emit(SpeakerChangedState());
        break;
      case LiveEventType.speechesCompleted:
        // Speeches done → result phase opens, status STILL live. Refresh so
        // resultPhaseOpen flips (speeches_completed_at / rooms.result.open) and
        // the result room becomes available without waiting for the 10s poll.
        dlog('mode', 'speeches_completed → result phase open (status still live)');
        _refreshLiveState();
        emit(LobbyModeChangedState());
        break;
      case LiveEventType.debateCompleted:
        _refreshLiveState();
        emit(DebateFinishedState());
        break;
      case LiveEventType.resultRevealed:
        _refreshLiveState();
        emit(ResultRevealedState());
        _signalResultNav(); // Every device opens the shared result
        break;
      case LiveEventType.poiRaised:
        if (event.byUserId != null) {
          _poiRaisedUserIds.add(event.byUserId!);
          emit(POIChangedState());
        }
        break;
      case LiveEventType.poiAnswered:
        final asker = event.byUserId;
        if (asker != null) _poiRaisedUserIds.remove(asker);
        // If I'm the asker, learn the outcome — always clear my "asking"
        // toolbar state; on ACCEPT, reopen my mic (lock-exempt) + show the mic
        // dialog (the screen also pushes the "POI accepted" news).
        if (asker == _myUserId) {
          isLocalAskingPOI = false;
          _poiTimer?.cancel();
          if (event.poiAccepted) {
            dlog('poi', 'my POI was ACCEPTED → reopening mic + asker dialog');
            localPoiAccepted = true; // exempts me from the publish-lock
            emit(POIAcceptedForLocalState());
          } else {
            dlog('poi', 'my POI was refused → clearing my raised hand');
          }
        }
        emit(POIChangedState());
        break;
      case LiveEventType.timerUpdate:
        // Server-authoritative timer. Reconcile this device's clock to the
        // server's pause/resume/no-judge state — the single source of truth.
        dlog('timer', 'timer_update → paused=${event.timerIsPaused} '
            'pausedElapsed=${event.timerPausedElapsedSeconds} '
            'stage=${event.currentStage} reason=${event.pauseReason}');
        if (event.currentStage != null) _currentStage = event.currentStage!;
        _applyServerTimer(
          stageStartedAt: DateTime.tryParse(event.currentStageStartedAt ?? '')?.toUtc(),
          serverNow: DateTime.tryParse(event.serverNow ?? '')?.toUtc(),
          paused: event.timerIsPaused,
          pausedElapsed: event.timerPausedElapsedSeconds,
        );
        emit(TimerTickedState());
        break;
      case LiveEventType.timeUpdate:
        // Legacy peer timer — retired as the source of truth. Ignored;
        // the server `timer_update` drives the clock now.
        break;
      case LiveEventType.timeControl:
        // Legacy peer pause/resume — superseded by server `timer_update`.
        break;
      case LiveEventType.lobbyOverlay:
        // Chair paused/resumed into the open-lobby grid (peer signal). Mirror the
        // overlay locally so this device switches view; the paired time_control
        // pause/resume freezes/continues the clock.
        dlog('mode', 'lobby_overlay received → ${event.lobbyOverlayEnabled}');
        _lobbyOverlay = event.lobbyOverlayEnabled;
        _clearPois(); // A toggle clears in-flight POIs
        emit(LobbyModeChangedState());
        break;
      case LiveEventType.teamChat:
        dlog('chat', 'TEAM CHAT received → team=${event.teamId} '
            'from=${event.senderName}: "${event.message}"');
        final incomingSenderId = event.senderId ?? '';
        // The unread dot is derived from seenBy, not a separate counter.
        // While the dialog is open the user is looking at this live, so mark
        // it seen immediately; otherwise it stays unread until they open chat
        // (setTeamChatOpen marks it locally + tells the backend).
        final seenBy = {incomingSenderId, if (_chatOpen) _myUserId.toString()}
            .toList();
        _chat.add(TeamChatMessage(
          teamId: event.teamId ?? '',
          senderId: incomingSenderId,
          senderName: event.senderName ?? '',
          message: event.message ?? '',
          ts: event.ts,
          seenBy: seenBy,
        ));
        emit(TeamChatUpdatedState());
        break;
      case LiveEventType.forceMute:
        if (event.targetUserId == _myUserId && isMicEnabled) {
          dlog('moderation', 'force_mute received for me → turning mic off');
          toggleMic();
        }
        break;
      case LiveEventType.forceCameraOff:
        if (event.targetUserId == _myUserId && isCameraEnabled) {
          dlog('moderation', 'force_camera_off received for me → turning camera off');
          toggleCamera();
        }
        break;
      case LiveEventType.publishLock:
        _muteAllActive = event.muteAllMic;
        _cameraAllOff = event.cameraAllOff;
        _micLockedIds
          ..clear()
          ..addAll(event.micLockedIds);
        _cameraLockedIds
          ..clear()
          ..addAll(event.cameraLockedIds);
        dlog('moderation', 'publish_lock → muteAllMic=$_muteAllActive '
            'cameraAllOff=$_cameraAllOff micLocked=$_micLockedIds '
            'cameraLocked=$_cameraLockedIds | canPublishNow=$canPublishNow '
            'canEnableCameraNow=$canEnableCameraNow');
        _enforcePublishLock();
        emit(PublishLockChangedState());
        break;
      case LiveEventType.roomClosed:
        dlog('moderation', 'room_closed received → tearing down the call UI');
        _roomClosed = true;
        emit(RoomClosedState());
        break;
    }
  }

  void _onStageChanged(LiveEvent e) {
    final previousStage = _currentStage;
    _clearPois(); // A new speech clears any leftover raised hands
    dlog('stage', 'stage_changed → currentStage=${e.currentStage} '
        'speakerUserId=${e.speakerUserId} serverStartedAt=${e.serverStartedAt} '
        'durationSeconds=${e.durationSeconds}');
    _currentStage = e.currentStage ?? _currentStage;
    _currentSpeakerUserId = e.speakerUserId;
    _serverStartedAt = DateTime.tryParse(e.serverStartedAt ?? '')?.toUtc();
    _rebuildTimeline(e.durationSeconds ?? _stageByOrder(_currentStage)?.durationSeconds);
    // Seed elapsed from the server start, then run the local timer.
    final started = _serverStartedAt;
    elapsedSeconds = started == null
        ? 0
        : DateTime.now().toUtc().difference(started).inSeconds.clamp(0, 1 << 30);
    // The lobby↔debate switch only rebuilds on LobbyModeChangedState, but a
    // *lobby→debate* transition arrives via stage_changed (which only emitted
    // SpeakerChangedState before) — so the screen never flipped. Emit it here.
    if ((previousStage <= 0) != (_currentStage <= 0)) {
      dlog('mode', 'TYPE CHANGE open↔main: stage $previousStage→$_currentStage '
          '→ isLobbyMode=${_currentStage <= 0}');
    }
    emit(LobbyModeChangedState());
    emit(SpeakerChangedState());
    emit(DebateTimelineEventState(DebateTimelineEvent.speechStarted));
    startTimer();
    // Sync the AUTHORITATIVE timer + stage duration together with the stage
    // switch: the broadcast can omit/mis-carry the duration, which briefly showed
    // the wrong (default) time until the next poll corrected it. Re-fetching
    // live-state here (the backend persists the stage before broadcasting, same
    // as the chair's own path) makes the timer land on the right value at once.
    _refreshLiveState();
  }

  void _publish(List<int> bytes) {
    _logOutgoing(bytes);
    final lp = _room?.localParticipant;
    if (lp == null) {
      dlog('socket-send', 'DROPPED — not connected (localParticipant null)');
      return;
    }
    // diagnostic: confirm the publish was accepted by the SFU. A throw here
    // is the tell-tale of a missing `canPublishData` grant (the root cause) —
    // surface it instead of swallowing it, so a future regression is obvious.
    lp.publishData(bytes, reliable: true).catchError((Object e) {
      dlog('socket-send', 'publishData FAILED — canPublishData grant or '
          'connection issue: $e');
    });
  }

  /// Trace every outbound data-channel message in full (POI flashes, team chat,
  /// publish-lock, lobby overlay, time controls…) so the sender side of a
  /// cross-device issue is visible too. The chair's per-second `time_update` is
  /// skipped to keep the trace/file readable.
  void _logOutgoing(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map && decoded['event'] == LiveEventType.timeUpdate.wire) return;
      final ev = decoded is Map ? decoded['event'] : '?';
      dlogJson('socket-send', 'publish event=$ev', decoded);
    } catch (_) {/* never let logging break a broadcast */}
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Media
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void toggleMic() {
    isMicEnabled = !isMicEnabled;
    dlog('media', 'LOCAL mic ${isMicEnabled ? "ON (unmute)" : "OFF (mute)"} '
        '| userId=$_myUserId canPublishNow=$canPublishNow');
    final muteFuture = _room?.localParticipant?.setMicrophoneEnabled(isMicEnabled);
    localAudioTrack = _localAudioTrack();
    // Opening the mic resolves the "talking while muted" situation → clear the
    // banner and (re)decide whether the probe should run at all.
    if (isMicEnabled) _clearMutedSpeaking();
    // LiveKit's setMicrophoneEnabled(false) stops the native mic capture as
    // part of muting; starting the muted-voice probe's own capture track
    // before that settles races the same OS audio device and can silently
    // fail to start, which is why the probe used to just never fire. Wait
    // for the mute/unmute to finish before (re)syncing the probe.
    if (muteFuture != null) {
      muteFuture.then((_) {
        _syncMutedVoiceMonitor();
        // The synchronous read above ran before the mute settled and can hold
        // a stale/torn-down handle — re-derive once the toggle is final so the
        // UI reflects the real post-toggle track.
        if (!isClosed) {
          localAudioTrack = _localAudioTrack();
          emit(LocalTrackUpdatedState());
        }
      });
    } else {
      _syncMutedVoiceMonitor();
    }
    emit(MicToggledState());
    emit(LocalTrackUpdatedState());
  }

  @override
  void toggleCamera() {
    isCameraEnabled = !isCameraEnabled;
    dlog('media', 'LOCAL camera ${isCameraEnabled ? "ON" : "OFF"} '
        '| userId=$_myUserId canEnableCameraNow=$canEnableCameraNow');
    _room?.localParticipant?.setCameraEnabled(isCameraEnabled);
    localVideoTrack = _localVideoTrack();
    emit(CameraToggledState());
    emit(LocalTrackUpdatedState());
  }

  // ── Muted-but-speaking detection ─────────────────────────────────────────────

  @override
  bool get mutedSpeakingActive => _mutedSpeakingDetected && !_mutedBannerDismissed;

  @override
  void dismissMutedSpeakingBanner() {
    if (_mutedBannerDismissed) return;
    dlog('media', 'muted-speaking banner DISMISSED (swipe)');
    _mutedBannerDismissed = true;
    emit(MutedSpeakingChangedState());
  }

  /// The probe only runs while it can matter: connected, mic off, and the local
  /// user is either holding the floor or a judge. Never for a guest — it opens
  /// the microphone, which they can't publish anyway.
  bool get _shouldMonitorMutedVoice =>
      _room != null &&
      !asGuest &&
      !isMicEnabled &&
      (_iAmCurrentSpeaker || _debateRole.isJudge);

  /// Start/stop the probe to match [_shouldMonitorMutedVoice]. Cheap to call on
  /// every mic toggle / live-state apply — it only acts on a transition.
  Future<void> _syncMutedVoiceMonitor() async {
    final want = _shouldMonitorMutedVoice;
    if (want && _mutedVoiceTrack == null && !_mutedMonitorStarting) {
      _mutedMonitorStarting = true;
      try {
        final track = await LocalAudioTrack.create(const AudioCaptureOptions());
        // Condition may have flipped while getUserMedia was in flight.
        if (!_shouldMonitorMutedVoice || isClosed) {
          await track.dispose();
          return;
        }
        final visualizer = createVisualizer(
          track,
          options: const AudioVisualizerOptions(barCount: 7),
        );
        final listener = visualizer.createListener()
          ..on<AudioVisualizerEvent>(_onMutedVoiceEvent);
        _mutedVoiceTrack = track;
        _mutedVoiceVisualizer = visualizer;
        _mutedVoiceListener = listener;
        _mutedVoiceEvents = 0;
        await visualizer.start();
        // `AudioVisualizerNative.start` ignores the native call's success
        // flag, so a "track not found" on the platform side would leave us
        // with an EventChannel that simply never emits. Say so out loud.
        _mutedVoiceWatchdog?.cancel();
        _mutedVoiceWatchdog = Timer(kMutedVoiceWatchdog, () {
          if (_mutedVoiceEvents == 0) {
            dlog('media', 'muted-voice probe DEAD — no visualizer window in '
                '${kMutedVoiceWatchdog.inSeconds}s; the native analyzer never '
                'attached to the probe track (banner cannot fire)');
          }
        });
        dlog('media', 'muted-voice probe STARTED '
            '(minPeak=$kMutedVoiceMinPeak, margin=$kMutedVoiceMargin, '
            'hold=${kMutedVoiceHold.inMilliseconds}ms, role=${_debateRole.wire})');
      } catch (e) {
        dlog('media', 'muted-voice probe failed to start: $e');
      } finally {
        _mutedMonitorStarting = false;
      }
    } else if (!want && _mutedVoiceTrack != null) {
      await _stopMutedVoiceMonitor();
    }
  }

  void _onMutedVoiceEvent(AudioVisualizerEvent e) {
    _mutedVoiceEvents++;
    // First window proves the native pipeline is alive — the watchdog that
    // would have reported it dead is no longer needed.
    _mutedVoiceWatchdog?.cancel();
    _mutedVoiceWatchdog = null;
    if (!_shouldMonitorMutedVoice) return;

    // Peak band, not the mean — see the note on [kMutedVoiceMinPeak].
    var peak = 0.0;
    for (final v in e.event) {
      if (v is num) {
        final d = v.toDouble();
        if (d > peak) peak = d;
      }
    }

    final trigger = math.max(kMutedVoiceMinPeak, _mutedVoiceFloor + kMutedVoiceMargin);
    final now = DateTime.now();

    // A periodic trace of what the mic is really producing, so a device that
    // still misbehaves can be diagnosed from the JADAL_DEBATE log instead of
    // guesswork.
    if (_mutedVoiceLastTrace == null ||
        now.difference(_mutedVoiceLastTrace!) > const Duration(seconds: 2)) {
      _mutedVoiceLastTrace = now;
      dlog('media', 'muted-voice level peak=${peak.toStringAsFixed(3)} '
          'floor=${_mutedVoiceFloor.toStringAsFixed(3)} '
          'trigger=${trigger.toStringAsFixed(3)} windows=$_mutedVoiceEvents');
    }

    if (peak >= trigger) {
      _mutedVoiceLoudSince ??= now;
      final heldFor = now.difference(_mutedVoiceLoudSince!);
      if (heldFor >= kMutedVoiceHold && !_mutedSpeakingDetected) {
        _mutedSpeakingDetected = true;
        dlog('media', 'MUTED-SPEAKING detected (peak=${peak.toStringAsFixed(3)} '
            '≥ trigger=${trigger.toStringAsFixed(3)} for ${heldFor.inMilliseconds}ms) '
            '→ showing banner');
        if (!isClosed) emit(MutedSpeakingChangedState());
      }
    } else {
      _mutedVoiceLoudSince = null;
      // Learn the quiet level only while below the trigger, so someone talking
      // can never raise the floor above their own voice.
      _mutedVoiceFloor =
          _mutedVoiceFloor * (1 - kMutedVoiceFloorAlpha) + peak * kMutedVoiceFloorAlpha;
    }
  }

  Future<void> _stopMutedVoiceMonitor() async {
    _mutedVoiceWatchdog?.cancel();
    _mutedVoiceWatchdog = null;
    final track = _mutedVoiceTrack;
    final visualizer = _mutedVoiceVisualizer;
    final listener = _mutedVoiceListener;
    if (track == null && visualizer == null) return;
    _mutedVoiceTrack = null;
    _mutedVoiceVisualizer = null;
    _mutedVoiceListener = null;
    dlog('media', 'muted-voice probe STOPPED (windows=$_mutedVoiceEvents)');
    try {
      await visualizer?.stop();
      await visualizer?.dispose();
    } catch (_) {}
    try {
      await listener?.dispose();
    } catch (_) {}
    try {
      await track?.stop();
      await track?.dispose();
    } catch (_) {}
    _clearMutedSpeaking();
  }

  /// Reset detection + the swipe-dismiss suppression (mic opened / role or
  /// speaker changed / probe stopped).
  void _clearMutedSpeaking() {
    _mutedVoiceLoudSince = null;
    _mutedVoiceFloor = 0;
    final wasVisible = mutedSpeakingActive;
    _mutedSpeakingDetected = false;
    _mutedBannerDismissed = false;
    if (wasVisible && !isClosed) emit(MutedSpeakingChangedState());
  }

  @override
  bool remoteHasAudio(String sid) => _remoteHasAudio[sid] ?? false;
  @override
  bool remoteHasVideo(String sid) => _remoteHasVideo[sid] ?? false;
  @override
  bool remoteSpeaking(String sid) => _remoteSpeaking[sid] ?? false;
  @override
  VideoTrack? remoteVideoTrack(RemoteParticipant p) =>
      p.videoTrackPublications.firstOrNull?.track;

  @override
  String firstName(String? full) {
    final name = (full ?? '').trim();
    if (name.isEmpty) return 'User';
    return name.split(' ').first;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Timer (chair-broadcast)
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void startTimer() {
    isPaused = false;
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isPaused || isClosed) return;
      elapsedSeconds++;
      final event = timeline.eventAt(elapsedSeconds, isReply: currentSlot?.isReply ?? false);
      if (event != null) emit(DebateTimelineEventState(event));
      emit(TimerTickedState());
      // The timer is SERVER-authoritative — no peer `time_update`
      // broadcast anymore. This is a cosmetic local tick that the next live-state
      // poll / `timer_update` reconciles.
    });
  }

  /// Apply the server-authoritative timer — compute elapsed from the
  /// server clock + persisted paused state, and run the cosmetic local tick only
  /// while the server says the clock is running. Called on every live-state apply
  /// and every `timer_update`, so all devices converge and a rejoin restores the
  /// exact (incl. paused) clock.
  void _applyServerTimer({
    required DateTime? stageStartedAt,
    required DateTime? serverNow,
    required bool paused,
    required int pausedElapsed,
  }) {
    if (_currentStage <= 0) {
      _resetTimerSilently(); // lobby / intro → no clock
      return;
    }
    if (paused) {
      elapsedSeconds = pausedElapsed.clamp(0, 1 << 30);
      isPaused = true;
      _localTimer?.cancel();
      emit(TimerTickedState());
      return;
    }
    if (stageStartedAt != null) {
      // offset = server − client; add it to the client clock to track the server.
      final offset = serverNow?.difference(DateTime.now().toUtc()) ?? Duration.zero;
      final adjustedNow = DateTime.now().toUtc().add(offset);
      elapsedSeconds =
          adjustedNow.difference(stageStartedAt).inSeconds.clamp(0, 1 << 30);
    }
    isPaused = false;
    startTimer(); // run the cosmetic local tick from the seeded value
  }

  @override
  void pauseTimer() {
    // Local cosmetic freeze; the AUTHORITATIVE pause goes through `toggleTimerPause`
    // → POST /timer (server broadcasts `timer_update`).
    isPaused = true;
    _localTimer?.cancel();
    emit(TimerTickedState());
  }

  @override
  void resumeTimer() => startTimer();

  @override
  void resetTimer() {
    elapsedSeconds = 0;
    isPaused = true;
    _localTimer?.cancel();
    emit(TimerTickedState());
  }

  void _resetTimerSilently() {
    elapsedSeconds = 0;
    isPaused = true;
    _localTimer?.cancel();
  }

  @override
  DebateTier get currentTier =>
      timeline.tierAt(elapsedSeconds, isReply: currentSlot?.isReply ?? false);
  @override
  bool get poiOpen =>
      timeline.poiOpenAt(elapsedSeconds, isReply: currentSlot?.isReply ?? false) &&
          currentSlot != null;

  // ──────────────────────────────────────────────────────────────────────────
  // Stage flow (chair-driven)
  // ──────────────────────────────────────────────────────────────────────────

  @override
  bool get debateStarted => _currentStage > 0;
  @override
  bool get debateFinished => _state?.debate.isCompleted ?? false;
  @override
  bool get isLastStep {
    final total = _state?.format.totalStages ?? _state?.stages.length ?? 0;
    return _currentStage >= total && total > 0;
  }

  /// Chair's next-state button → POST /next-stage (start / next / complete).
  /// Everyone else updates from the resulting `stage_changed`/`debate_completed`.
  @override
  bool get isAdvancingStage => _advancingStage;

  @override
  void advanceDebate() {
    if (!isAuthority) {
      dlog('action', 'advanceDebate IGNORED — not authority (role=${_debateRole.wire})');
      return;
    }
    // Guard against the chair double-tapping a laggy server into skipping a
    // speech; the room paints a blocking overlay while this is true.
    if (_advancingStage) {
      dlog('action', 'advanceDebate IGNORED — a next-stage request is already in flight');
      return;
    }
    _advancingStage = true;
    emit(StageAdvancingChangedState());
    dlog('action', 'NEXT-STAGE ▸ POST next-stage (currentStage=$_currentStage, '
        'isLastStep=$isLastStep)');
    repo.nextStage(debateId).then((res) => res.fold(
          (f) {
            dlog('action', 'next-stage FAILED: ${f.message}');
            _advancingStage = false;
            emit(StageAdvancingChangedState());
            emit(DebateErrorState(f.message));
          },
          (_) {
            dlog('action', 'next-stage OK — refreshing live-state (safety net)');
            _refreshLiveState();
            _advancingStage = false;
            emit(StageAdvancingChangedState());
          },
        ));
  }

  @override
  void startAsFirstSpeaker() {/* backend: the chair starts via the button */}

  @override
  void markDebateDone() {
    if (!isAuthority) return;
    dlog('action', 'markDebateDone ▸ POST next-stage (finish)');
    repo.nextStage(debateId).then((res) => res.fold(
          (f) => emit(DebateErrorState(f.message)),
          (_) => _refreshLiveState(),
        ));
  }

  /// Chair: discard the current stage and return to the lobby (stage 0).
  void rollbackToLobby() {
    if (!isAuthority) return;
    dlog('action', 'rollbackToLobby ▸ POST rollback-to-lobby');
    repo.rollbackToLobby(debateId).then((res) => res.fold(
          (f) => emit(DebateErrorState(f.message)),
          (_) => _refreshLiveState(),
        ));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Speaker resolution
  // ──────────────────────────────────────────────────────────────────────────

  @override
  DebateSide get localSide {
    final side = _state?.sideForUser(_myUserId);
    return side == 'opposition' ? DebateSide.opposition : DebateSide.proposition;
  }

  @override
  SpeechSlot? get currentSlot {
    if (_currentStage <= 0) return null;
    final uid = _currentSpeakerUserId;
    if (uid == null) return null;
    final sideStr = _state?.sideForUser(uid);
    if (sideStr == null) return null;
    final side = sideStr == 'opposition' ? DebateSide.opposition : DebateSide.proposition;
    final idx = teamFor(side).debaters.indexWhere((d) => d.id == uid.toString());
    if (idx < 0) return null;
    return SpeechSlot(side: side, orderIndex: idx, isReply: _stageByOrder(_currentStage)?.isReply ?? false);
  }

  @override
  DebateSide get currentSpeakerSide => currentSlot?.side ?? DebateSide.proposition;

  @override
  TeamInfo teamFor(DebateSide side) =>
      side == DebateSide.proposition ? _data.propositionTeam : _data.oppositionTeam;

  /// Drive the fixed slot count from the backend format's `speakers_per_side`.
  @override
  int get speakersPerSide => _data.slotsPerSide;

  @override
  SpeakerOrder orderFor(DebateSide side) =>
      side == DebateSide.proposition ? propOrder : oppOrder;

  @override
  Debater debaterAt(DebateSide side, int orderIndex) {
    final team = teamFor(side);
    if (orderIndex >= 0 && orderIndex < team.debaters.length) {
      return team.debaters[orderIndex];
    }
    return const Debater(id: '', name: '—', ranking: 0);
  }

  @override
  String roleLabel(DebateSide side, int orderIndex) {
    final base = '${side.rolePrefix}${orderIndex + 1}';
    final order = orderFor(side);
    if (_data.format.replySpeech &&
        order.replySpeakerId != null &&
        order.orderedSpeakerIds.length > orderIndex &&
        order.orderedSpeakerIds[orderIndex] == order.replySpeakerId) {
      return '$base - ${side.replySuffix}';
    }
    return base;
  }

  @override
  String roleLabelForSlot(SpeechSlot slot) {
    if (slot.isReply) return slot.side.replySuffix;
    return roleLabel(slot.side, slot.orderIndex);
  }

  @override
  bool isCurrentSpeaker(DebateSide side, int orderIndex) {
    final slot = currentSlot;
    if (slot == null) return false;
    return slot.side == side && slot.orderIndex == orderIndex;
  }

  @override
  void setSpeakerOrder({
    required String teamId,
    required List<String> orderedSpeakerIds,
    String? replySpeakerId,
  }) {
    final side = teamId == _data.propositionTeam.teamId
        ? 'proposition'
        : (teamId == _data.oppositionTeam.teamId ? 'opposition' : null);
    if (side == null) return;
    final order = SpeakerOrder(
      orderedSpeakerIds: orderedSpeakerIds,
      replySpeakerId: replySpeakerId,
      isSet: true,
    );
    if (side == 'proposition') {
      propOrder = order;
    } else {
      oppOrder = order;
    }
    repo.setTeamSpeakers(
      debateId: debateId,
      side: side,
      speakerUserIds: orderedSpeakerIds.map(int.parse).toList(),
      replySpeakerUserId: replySpeakerId == null ? null : int.tryParse(replySpeakerId),
    );
    emit(SpeakerOrderChangedState());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // POI (best-effort mapping to the test-shaped widgets)
  // ──────────────────────────────────────────────────────────────────────────

  int? get _currentPhaseId => _stageByOrder(_currentStage)?.id;

  @override
  void sendPOIRequest() {
    isLocalAskingPOI = true;
    _poiRaisedUserIds.add(_myUserId);
    final phaseId = _currentPhaseId;
    dlog('poi', 'POI raised by me (userId=$_myUserId, phaseId=$phaseId)');
    // ALWAYS broadcast the peer flash so every other device shows the POI,
    // even when the phase id is null (the old code skipped this when phaseId was
    // null → the POI stayed local). Only the REST persistence needs the phase id.
    _publish(LiveDebateSocket.poiRaised(stagePhaseId: phaseId, byUserId: _myUserId));
    if (phaseId != null) {
      repo.sendPoi(debateId: debateId, phaseId: phaseId, action: 'raise');
    }
    emit(POIChangedState());
    _poiTimer?.cancel();
    _poiTimer = Timer(const Duration(seconds: 15), () {
      isLocalAskingPOI = false;
      _poiRaisedUserIds.remove(_myUserId);
      if (!isClosed) emit(POIChangedState());
    });
  }

  @override
  void acceptPOI(String askerUserId) {
    final phaseId = _currentPhaseId;
    // Answer the SPECIFIC asker (by user id) so two simultaneous askers are
    // disambiguated — clear only that asker and tell every device to drop that
    // asker's badge (`by_user_id` = the asker being answered).
    final askerId = int.tryParse(askerUserId);
    dlog('poi', 'POI ACCEPTED (asker=$askerUserId, phaseId=$phaseId)');
    // Always broadcast the answer flash with accepted=true so the asker
    // learns it (reopens their mic + sees the dialog/news). Persistence needs the id.
    _publish(LiveDebateSocket.poiAnswered(
        stagePhaseId: phaseId, byUserId: askerId ?? _myUserId, accepted: true));
    if (phaseId != null) {
      repo.sendPoi(debateId: debateId, phaseId: phaseId, action: 'answer');
    }
    if (askerId != null) {
      _poiRaisedUserIds.remove(askerId);
    } else {
      _poiRaisedUserIds.clear();
    }
    emit(POIChangedState());
  }

  @override
  void refusePOI(String askerUserId) {
    // Dismiss the specific asker — and BROADCAST accepted=false so the
    // asker's own raised hand + toolbar POI button clear too (not just locally on
    // the speaker's device).
    final uid = int.tryParse(askerUserId);
    if (uid != null) {
      dlog('poi', 'POI REFUSED (asker=$uid)');
      _publish(LiveDebateSocket.poiAnswered(
          stagePhaseId: _currentPhaseId, byUserId: uid, accepted: false));
      _poiRaisedUserIds.remove(uid);
    }
    if (askerUserId == 'local' || uid == _myUserId) isLocalAskingPOI = false;
    emit(POIChangedState());
  }

  @override
  void poiDone() {
    localPoiAccepted = false;
    isLocalAskingPOI = false;
    _poiRaisedUserIds.remove(_myUserId);
    if (isMicEnabled) toggleMic();
    emit(POIChangedState());
  }

  /// Drop all in-flight POIs — called on a stage change and on an
  /// open↔live toggle so a raised hand never lingers into the next speech or the
  /// lobby (a stale POI the next speaker would otherwise "see").
  void _clearPois() {
    if (_poiRaisedUserIds.isEmpty && !isLocalAskingPOI) return;
    dlog('poi', 'clearing in-flight POIs (stage change / lobby toggle)');
    _poiRaisedUserIds.clear();
    isLocalAskingPOI = false;
    _poiTimer?.cancel();
    emit(POIChangedState());
  }

  @override
  bool isAskingPOIByDebater(String debaterId) {
    final uid = int.tryParse(debaterId);
    return uid != null && _poiRaisedUserIds.contains(uid);
  }

  @override
  bool isAskingPOIBySid(String sid) => false;
  @override
  Set<String> get askingPoiSids =>
      _poiRaisedUserIds.map((e) => e.toString()).toSet();

  @override
  Set<String> get presentIds {
    final ids = <String>{if (_myUserId != 0) _myUserId.toString()};
    for (final p in participants) {
      if (p.identity.isNotEmpty) ids.add(p.identity);
    }
    return ids;
  }

  // ── Real presence (backend) — keyed off the LiveKit participant identity ─────

  @override
  bool isLocalUserId(String userId) => userId == _myUserId.toString();

  @override
  bool isUserPresent(String userId) {
    if (isLocalUserId(userId)) return true;
    return remoteParticipantById(userId) != null;
  }

  @override
  RemoteParticipant? remoteParticipantById(String userId) {
    for (final p in participants) {
      if (p.identity == userId) return p;
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // News / chat / lobby / moderation
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void updateLatestNews(String message) {
    dlog('news', 'NEWS BAR updated → "$message"');
    latestNews = message;
    emit(NewsUpdatedState());
  }

  @override
  void pushRandomNews(String Function(int n) build) =>
      updateLatestNews(build(_newsCounter++));

  /// The open lobby is shown before the live session (real stage 0, NOT intro),
  /// during a chair PAUSE overlay mid-debate, or in the result phase. The intro
  /// shows the live layout (chair welcome), so it is NOT lobby mode.
  @override
  bool get isLobbyMode =>
      _lobbyOverlay || resultPhaseOpen || (_currentStage <= 0 && !isIntro);

  /// The chair has entered the live session but no speech yet (welcome).
  @override
  bool get isIntro => _state?.debate.isIntroPhase ?? false;

  /// The chair shown in the main speaker card during the intro.
  @override
  String? get introHostId => _state?.chairJudge?.user.id.toString();
  @override
  String get introHostName => _state?.chairJudge?.user.name ?? '';

  /// Chair: enter the live session from the lobby → intro (chair welcome, no
  /// timer). The chair's "Start debate" (next-stage) then begins P1.
  @override
  Future<void> startLive() async {
    if (!isAuthority) return;
    dlog('action', 'START-LIVE ▸ POST start-live (enter intro)');
    final res = await repo.startLive(debateId);
    await res.fold(
      (f) async {
        dlog('action', 'start-live FAILED: ${f.message}');
        emit(DebateErrorState(f.message));
      },
      (_) async {
        await _refreshLiveState(); // picks up live_started_at → isIntro
        // Open lobby → live session: the media sweep (mute all + cameras off).
        // The chair may still open their own camera during the intro.
        _enforceLiveFormatMedia();
        emit(LobbyModeChangedState());
      },
    );
  }

  /// Chair toggle. Mid-debate it's a **pause overlay** that freezes the current
  /// speaker + server clock (resume continues from the same spot). From the
  /// open lobby it enters the **intro**, not P1.
  @override
  void setLobbyMode(bool enabled) {
    if (!isAuthority) {
      dlog('action', 'setLobbyMode IGNORED — not authority');
      return;
    }
    // Once the speeches are done (result phase open) the room stays in
    // the open lobby — the chair can't go back to a speech.
    if (!enabled && resultPhaseOpen) {
      dlog('action', 'setLobbyMode(live) IGNORED — result phase open (Issue 9)');
      return;
    }
    if (enabled) {
      // Pause into the open-lobby grid. At stage 0 there's nothing live to pause.
      if (_currentStage > 0 && !_lobbyOverlay) {
        dlog('action', 'OPEN-LOBBY pause ▸ freeze stage $_currentStage + timer '
            '(elapsed=$elapsedSeconds)');
        _lobbyOverlay = true;
        _clearPois(); // Clear in-flight POIs on the toggle
        _publish(LiveDebateSocket.lobbyOverlay(enabled: true));
        // AUTHORITATIVE pause via the server (persists + broadcasts), plus
        // an immediate local freeze for snappy feedback.
        repo.setTimer(debateId: debateId, action: 'pause');
        pauseTimer();
        emit(LobbyModeChangedState());
      }
    } else if (_lobbyOverlay) {
      // Resume the paused speaker exactly where they stopped. Back to the live
      // format ⇒ the media sweep: mute all + every camera off (audio-only).
      dlog('action', 'OPEN-LOBBY resume ▸ continue stage $_currentStage');
      _lobbyOverlay = false;
      _publish(LiveDebateSocket.lobbyOverlay(enabled: false));
      repo.setTimer(debateId: debateId, action: 'resume');
      resumeTimer();
      _enforceLiveFormatMedia();
      emit(LobbyModeChangedState());
    } else if (_currentStage <= 0 && !isIntro) {
      // Open lobby (pre-live) → enter the INTRO (chair welcome), not P1.
      startLive();
    } else {
      // Intro → "Start debate": begin the first speech.
      dlog('action', 'START DEBATE ▸ POST next-stage (from intro)');
      advanceDebate();
    }
  }

  /// / Update 1: the chair's stop/resume timer button. Drives the
  /// server-authoritative pause/resume; the server broadcasts `timer_update` so
  /// every device matches exactly.
  @override
  void toggleTimerPause() {
    if (!isAuthority) return;
    final action = isPaused ? 'resume' : 'pause';
    dlog('action', 'TIMER $action ▸ POST /timer');
    if (action == 'pause') {
      pauseTimer();
    } else {
      resumeTimer();
    }
    repo.setTimer(debateId: debateId, action: action).then((res) => res.fold(
          (f) {
            dlog('action', 'timer $action FAILED: ${f.message}');
            emit(DebateErrorState(f.message));
          },
          (_) => _refreshLiveState(),
        ));
  }

  // ── Immediate "turn off now" nudges (paired with the durable lock below) ─────

  @override
  void muteAll() {
    if (!isAuthority) return;
    dlog('action', 'muteAll (nudge) ▸ forcing every present non-exempt mic off');
    for (final p in participants) {
      final uid = int.tryParse(p.identity);
      if (uid != null && !_isUserExempt(uid)) _publish(LiveDebateSocket.forceMute(uid));
    }
  }

  /// Entering the live-debate format ("back to debate" / "go live") always
  /// applies: mute all (usual exemptions — judges + whoever holds the floor)
  /// plus camera off for EVERYONE with no exemptions, since live debate renders
  /// no video at all (the chair's intro-only camera right lives in
  /// [canEnableCameraNow], not here). Chair-only; each remote enforces its own
  /// side again via [_enforcePublishLock] when the new stage reaches it.
  void _enforceLiveFormatMedia() {
    if (!isAuthority) return;
    dlog('action', 'live-format media sweep ▸ mute all + camera off for all');
    muteAll();
    for (final p in participants) {
      final uid = int.tryParse(p.identity);
      if (uid != null) _publish(LiveDebateSocket.forceCameraOff(uid));
    }
    _enforcePublishLock(); // the chair's own device follows the same rules
  }

  @override
  void forceMute(String targetSid) {
    if (!isAuthority) return;
    dlog('action', 'forceMute (nudge) target=$targetSid');
    final uid = int.tryParse(targetSid);
    if (uid != null) _publish(LiveDebateSocket.forceMute(uid));
  }

  @override
  void forceCameraOff(String targetSid) {
    if (!isAuthority) return;
    dlog('action', 'forceCameraOff (nudge) target=$targetSid');
    final uid = int.tryParse(targetSid);
    if (uid != null) _publish(LiveDebateSocket.forceCameraOff(uid));
  }

  // ── Durable publish-lock (mic + camera), chair-broadcast ────────
  // Mirrors the mock's design: "mute all" / per-user lock *prevents opening* the
  // mic/camera (not just a one-off mute). Judges + whoever holds the floor are
  // always exempt. The chair broadcasts the lock; each client enforces it on
  // itself in [_enforcePublishLock] (forcing its own track off if it just lost
  // permission), so it works without LiveKit server APIs (client-cooperative).

  bool _isUserExempt(int uid) =>
      (_state?.isJudge(uid) ?? false) || _currentSpeakerUserId == uid;

  /// Judges + the current main speaker can always publish (never locked). B2: an
  /// asker whose POI was just accepted is also exempt so their mic reopens even
  /// if the chair had force-muted them.
  bool get _amExemptFromLock =>
      _debateRole.isJudge || _iAmCurrentSpeaker || localPoiAccepted;

  @override
  bool get muteAllActive => _muteAllActive;

  @override
  Set<String> get publishLockedIds => Set.unmodifiable(_micLockedIds);

  @override
  bool get canPublishNow {
    if (_amExemptFromLock) return true;
    if (_muteAllActive) return false;
    return !_micLockedIds.contains(_myUserId.toString());
  }

  @override
  bool get cameraAllOff => _cameraAllOff;

  @override
  Set<String> get cameraLockedIds => Set.unmodifiable(_cameraLockedIds);

  @override
  bool get canEnableCameraNow {
    // Judges + the current main speaker (+ an accepted POI asker) are always
    // exempt from being locked out — checked FIRST, mirroring canPublishNow.
    // A forced camera-off must only ever be a one-time nudge for them, never a
    // dead toggle button they can't recover from.
    if (_amExemptFromLock) return true;
    // The live-debate format is audio-only — video streaming is not rendered at
    // all — so nobody else may open a camera there (judges and viewers of every
    // kind included). The one exception: the chair during the intro (welcome),
    // before the first speaker starts. The open lobby / result phase
    // (isLobbyMode) keeps the usual lock rules below.
    if (!isLobbyMode && !(isIntro && isAuthority)) return false;
    if (_cameraAllOff) return false;
    return !_cameraLockedIds.contains(_myUserId.toString());
  }

  @override
  void toggleMuteAll() {
    if (!isAuthority) return;
    _muteAllActive = !_muteAllActive;
    dlog('action', 'toggleMuteAll → muteAllActive=$_muteAllActive');
    _broadcastPublishLock();
    if (_muteAllActive) muteAll(); // immediate nudge for everyone present
    _enforcePublishLock();
    emit(PublishLockChangedState());
  }

  @override
  void toggleCameraAll() {
    if (!isAuthority) return;
    _cameraAllOff = !_cameraAllOff;
    dlog('action', 'toggleCameraAll → cameraAllOff=$_cameraAllOff');
    _broadcastPublishLock();
    if (_cameraAllOff) {
      for (final p in participants) {
        final uid = int.tryParse(p.identity);
        if (uid != null && !_isUserExempt(uid)) {
          _publish(LiveDebateSocket.forceCameraOff(uid));
        }
      }
    }
    _enforcePublishLock();
    emit(PublishLockChangedState());
  }

  @override
  void toggleUserPublishLock(String userId) {
    if (!isAuthority) return;
    if (!_micLockedIds.add(userId)) _micLockedIds.remove(userId);
    final locked = _micLockedIds.contains(userId);
    dlog('action', 'toggleUserPublishLock user=$userId → micLocked=$locked');
    if (locked) forceMute(userId); // turn it off now + keep it locked
    _broadcastPublishLock();
    _enforcePublishLock();
    emit(PublishLockChangedState());
  }

  @override
  void toggleUserCameraLock(String userId) {
    if (!isAuthority) return;
    if (!_cameraLockedIds.add(userId)) _cameraLockedIds.remove(userId);
    final locked = _cameraLockedIds.contains(userId);
    dlog('action', 'toggleUserCameraLock user=$userId → cameraLocked=$locked');
    if (locked) forceCameraOff(userId);
    _broadcastPublishLock();
    _enforcePublishLock();
    emit(PublishLockChangedState());
  }

  void _broadcastPublishLock() => _publish(LiveDebateSocket.publishLock(
        muteAllMic: _muteAllActive,
        micLockedIds: _micLockedIds.toList(),
        cameraAllOff: _cameraAllOff,
        cameraLockedIds: _cameraLockedIds.toList(),
      ));

  /// If the local user just lost permission, force its own mic/camera off.
  void _enforcePublishLock() {
    if (!canPublishNow && isMicEnabled) toggleMic();
    if (!canEnableCameraNow && isCameraEnabled) toggleCamera();
  }

  @override
  void sendTeamChat({required String teamId, required String message}) {
    final senderName = localParticipant?.name.isNotEmpty == true
        ? localParticipant!.name
        : firstName(_data.propositionTeam.debaters.isNotEmpty
        ? _data.propositionTeam.debaters.first.name
        : 'User');
    final senderId = _myUserId.toString();
    final ts = DateTime.now().millisecondsSinceEpoch;
    dlog('chat', 'TEAM CHAT sent → team=$teamId from=$senderName: "$message"');
    _chat.add(TeamChatMessage(
      teamId: teamId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      ts: ts,
      seenBy: [senderId],
    ));
    _publish(LiveDebateSocket.teamChat(
      teamId: teamId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      ts: ts,
    ));
    emit(TeamChatUpdatedState());
    // Persist alongside the peer broadcast (which already delivered it live) —
    // this is what makes the message survive a leave+rejoin. Best-effort: a
    // failure here doesn't affect the live delivery that already happened.
    repo.sendChatMessage(debateId: debateId, message: message);
  }

  @override
  List<TeamChatMessage> chatFor(String viewerTeamId) =>
      _chat.where((m) => m.teamId == viewerTeamId).toList();

  @override
  int get unreadTeamChatCount {
    final myId = _myUserId.toString();
    return _chat
        .where((m) => m.teamId == myTeamId && !m.seenBy.contains(myId))
        .length;
  }

  @override
  void setTeamChatOpen(bool open) {
    _chatOpen = open;
    if (!open) return;
    // Mark everything currently unseen as seen-by-me locally (instant dot
    // clear) and tell the backend so it survives a rejoin.
    final myId = _myUserId.toString();
    var changed = false;
    for (var i = 0; i < _chat.length; i++) {
      final m = _chat[i];
      if (m.teamId == myTeamId && !m.seenBy.contains(myId)) {
        _chat[i] = m.copyWith(seenBy: [...m.seenBy, myId]);
        changed = true;
      }
    }
    repo.markChatRead(debateId);
    if (changed) {
      emit(TeamChatUpdatedState());
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Role → controls gating
  // ──────────────────────────────────────────────────────────────────────────

  bool get _iAmCurrentSpeaker => _currentSpeakerUserId == _myUserId;

  /// Only the real current speaker may answer a POI. In the lobby
  /// `_currentSpeakerUserId` is null → false for everyone.
  @override
  bool get iAmCurrentSpeaker => _iAmCurrentSpeaker;

  @override
  bool get isGuest => asGuest || _debateRole.isGuest;

  @override
  bool get canModerateOthers => isAuthority; // chair only
  @override
  bool get canControlStage => isAuthority;
  @override
  bool get canControlTimer => isAuthority;
  @override
  bool get canManageResult => isAuthority;
  @override
  bool get isSpectator =>
      !(_debateRole.isDebater || _debateRole.isJudge);
  // Guests hold a subscribe-only token, so the mic and camera would fail
  // anyway. The lobby exception that lets ordinary spectators publish must not
  // apply to them.
  @override
  bool get canUseMedia => !isGuest && (isLobbyMode || !isSpectator);
  @override
  bool get canAskPoi => !isGuest && _debateRole.isDebater;
  @override
  bool get poiEnabledNow {
    final slot = currentSlot;
    return canAskPoi && poiOpen && slot != null && slot.side != localSide;
  }

  @override
  bool get canOpenChat =>
      !isGuest && _debateRole.isDebater && !_iAmCurrentSpeaker;

  @override
  String? get shareUrl => isGuest ? null : _state?.debate.shareUrl;

  // ──────────────────────────────────────────────────────────────────────────
  // Result flow — REST actions; state read from live-state
  // ──────────────────────────────────────────────────────────────────────────

  @override
  List<ResultStageRef> get scoreableStages {
    final st = _state;
    if (st == null) return const [];
    return [
      for (final stage in st.stages)
            () {
          final sp = st.speakerByParticipantId(stage.participantId);
          return ResultStageRef(
            stageOrder: stage.orderIndex,
            roleLabel: stage.name.isNotEmpty ? stage.name : '#${stage.orderIndex}',
            speakerName: sp?.user.name ?? '',
            side: debateSideFromString(sp?.side),
            isReply: stage.isReply,
          );
        }(),
    ];
  }

  @override
  bool get isCancelled => _state?.debate.isCancelled ?? false;

  /// Result phase is open while the debate is still `live` — driven by the
  /// backend's `speeches_completed_at` / `rooms.result.open`, never by
  /// `status == completed`.
  @override
  bool get resultPhaseOpen =>
      (_state?.debate.speechesCompleted ?? false) ||
      (_state?.rooms.result.open ?? false) ||
      debateFinished;

  /// A result has been stored (chair post-submit / judges) — gates the
  /// live-room "share result" action.
  @override
  bool get hasResult => _state?.result != null || debateFinished;

  @override
  DebateResultView? get resultView {
    final st = _state;
    if (st == null) return null;
    // No view until a result is in (chair, post-submit) or the debate completed.
    if (st.result == null && !st.debate.isCompleted) return null;
    return DebateResultView.fromLiveState(st);
  }

  @override
  Future<bool> submitResult({
    required DebateSide winningSide,
    required Map<int, num> scoresByStageOrder,
    required String summaryNotes,
  }) async {
    if (!isAuthority) return false;
    final model = DebateResultModel(
      winningSide: winningSide == DebateSide.proposition ? 'proposition' : 'opposition',
      summaryNotes: summaryNotes,
      stageScores: [
        // The backend requires an INTEGER 0–100 per stage — round defensively
        // so a stray double can never trip the `must be an integer` validator.
        for (final e in scoresByStageOrder.entries)
          StageScore(stageOrder: e.key, score: e.value.round()),
      ],
    );
    dlog('action', 'SUBMIT RESULT ▸ POST result (winner=${winningSide.name}, '
        'stages=${scoresByStageOrder.length})');
    final res = await repo.submitResult(debateId: debateId, result: model);
    // Report the REAL outcome so the sheet never lies about success.
    return res.fold(
      (f) {
        dlog('action', 'submit-result FAILED: ${f.message}');
        emit(DebateErrorState(f.message));
        return false;
      },
      // Re-fetch so the chair sees the submitted result + the reveal button.
      (_) {
        dlog('action', 'submit-result OK — refreshing live-state');
        _refreshLiveState();
        return true;
      },
    );
  }

  @override
  Future<void> revealResult() async {
    if (!isAuthority) return;
    dlog('action', 'REVEAL RESULT ▸ POST result/reveal');
    final res = await repo.revealResult(debateId);
    await res.fold(
          (f) async {
            dlog('action', 'reveal-result FAILED: ${f.message}');
            emit(DebateErrorState(f.message));
          },
          (_) async {
        dlog('action', 'reveal-result OK — refreshing + confetti');
        await _refreshLiveState();
        emit(ResultRevealedState()); // confetti
      },
    );
  }

  @override
  Future<void> closeMain() async {
    if (!isAuthority) return;
    dlog('action', 'CLOSE-MAIN ▸ POST close-main');
    final res = await repo.closeMain(debateId);
    await res.fold(
          (f) async {
            dlog('action', 'close-main FAILED: ${f.message}');
            emit(DebateErrorState(f.message));
          },
          (_) async {
        // Reveals an existing result (no confetti) or cancels the debate.
        await _refreshLiveState();
        if (isCancelled) emit(DebateCancelledState());
      },
    );
  }

  // ── Share result / close room — backend stubs ────────────────────────
  // The dedicated endpoints (server-side publish-lock, kick-all, explicit
  // live→done) don't exist yet; map to what we have and TODO the rest.

  /// Navigate to the shared result exactly once (idempotent), driven
  /// by either the chair's share or the inbound `result_revealed` broadcast.
  void _signalResultNav() {
    if (_resultNavSignaled || isClosed) return;
    _resultNavSignaled = true;
    dlog('action', 'result shared/revealed → opening the result screen on this device');
    emit(NavigateToSharedResultState());
  }

  @override
  Future<void> shareResult() async {
    if (!isAuthority) return;
    // Closest existing behaviour: reveal the result to the room (confetti). The
    // explicit live→done stage flip is a TODO until the endpoint exists.
    // TODO(backend): POST a "complete/share result" route to flip live→done.
    await revealResult();
    _signalResultNav();
  }

  /// Sharing reveals the result, so `revealed` IS the shared flag. The
  /// base class returned a constant false, which kept the chair's "share
  /// result" actions visible after the result had already been shared.
  @override
  bool get resultShared => resultView?.revealed ?? false;

  @override
  bool get isRoomClosed => _roomClosed;

  /// Chair: force-close the room. The backend reveals a pending result or
  /// cancels the debate, broadcasts `room_closed`, then deletes the LiveKit room.
  @override
  Future<void> closeRoom() async {
    if (!isAuthority) {
      dlog('action', 'closeRoom IGNORED — not authority');
      return;
    }
    dlog('action', 'CLOSE-ROOM ▸ POST close-room (debateId=$debateId)');
    final res = await repo.closeRoom(debateId);
    await res.fold(
      (f) async {
        dlog('action', 'close-room FAILED: ${f.message}');
        emit(DebateErrorState(f.message));
      },
      (s) async {
        dlog('action', 'close-room OK — status=${s.debate.status}; '
            'awaiting room_closed broadcast to leave');
        _applyLiveState(s);
        _roomClosed = true;
        // The broadcast also fires; emit locally so the chair's device leaves too.
        emit(RoomClosedState());
      },
    );
  }

  @override
  Future<void> sendDebateRating(int rating, {String? comment}) async {
    final content = comment?.trim();
    final res = await repo.sendFeedback(
      debateId: debateId,
      type: 'rating_debate',
      rating: rating,
      content: (content == null || content.isEmpty) ? null : content,
    );
    res.fold(
          (f) => emit(DebateErrorState(f.message)),
          (_) => emit(LiveStateUpdatedState()),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  /// True while an intentional local leave is tearing the room down,
  /// so the RoomDisconnectedEvent listener stays quiet and can't double-pop
  /// the navigator behind the leave flow's own navigation.
  bool _userLeaving = false;

  @override
  Future<void> disconnect({bool notify = true}) async {
    dlog('leave',
        'LEAVE ▸ local user leaving the room (userId=$_myUserId, notify=$notify)');
    _userLeaving = true;
    _stopLiveStatePolling();
    await _stopMutedVoiceMonitor();
    await _room?.disconnect();
    await _roomEvents?.dispose();
    _connectionQualityTimer?.cancel();
    _localTimer?.cancel();
    _poiTimer?.cancel();
    _userLeaving = false;
    if (notify && !isClosed) {
      emit(DebateDisconnectedState(reason: 'User left the debate'));
    }
  }

  @override
  Future<void> close() async {
    _stopLiveStatePolling();
    await _stopMutedVoiceMonitor();
    await _room?.dispose();
    await _roomEvents?.dispose();
    _connectionQualityTimer?.cancel();
    _localTimer?.cancel();
    _poiTimer?.cancel();
    return super.close();
  }
}