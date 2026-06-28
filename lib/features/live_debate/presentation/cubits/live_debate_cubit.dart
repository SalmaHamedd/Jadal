import 'dart:async';
import 'dart:convert';

import 'package:livekit_client/livekit_client.dart';

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

/// Backend-connected live-debate controller (§7). REST drives actions; the
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
  })  : _data = BackendLiveDebateData.empty(),
        super(DebateInitialState()) {
    _timeline = DebateTimeline(_data.format);
  }

  final LiveDebateRepository repo;
  final ProfileRepository profileRepo;
  final int debateId;

  /// Keep-local-vs-snap threshold for the chair-broadcast timer (§7). Issue 6:
  /// the tester's spec — within 1s keep the local clock, otherwise snap to the
  /// authority's value then keep ticking locally.
  static const int kTimerSyncOffsetSeconds = 1;

  // ── State ──────────────────────────────────────────────────────────────────
  LiveStateModel? _state;
  BackendLiveDebateData _data;
  int _myUserId = 0;
  DebateRoomRole _role = DebateRoomRole.unknown;
  int? _electedChairUserId;
  bool _isReady = false;

  /// FE-9: tracks authority so a non-authority→authority transition (a chair
  /// hand-off picked up by live-state / the FE-10 poll, without a rejoin) can
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

  /// FE-10: periodic `live-state` re-fetch. Self-heals a missed `chair_elected`
  /// (FE-9) and a dropped participant join/leave — the screen rebuilds into the
  /// correct state without anyone leaving — and (with the new logging) prints the
  /// fresh backend payload + digest every tick so issues are diagnosable live.
  Timer? _pollTimer;
  static const Duration kLiveStatePollInterval = Duration(seconds: 10);
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
  ///
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

  /// The chair is the timer/flow authority (§7). Trusts the live-state chair
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

  // ── Moderation publish-lock (mic + camera) + close-room (§FE-4/FE-6/FE-7) ────
  bool _muteAllActive = false;
  bool _cameraAllOff = false;
  final Set<String> _micLockedIds = {};
  final Set<String> _cameraLockedIds = {};
  bool _roomClosed = false;

  /// Issue 10: emit the "go to the shared result" navigation exactly once,
  /// whether it's triggered by the chair sharing or by the inbound
  /// `result_revealed` broadcast (the chair receives its own broadcast too).
  bool _resultNavSignaled = false;

  /// Chair-driven open-lobby PAUSE overlay (§open-lobby): a break that freezes the
  /// current speaker + timer where they are (so it resumes from the same spot)
  /// WITHOUT advancing/rolling-back the backend stage. Distinct from the real
  /// stage-0 lobby (`_currentStage <= 0`).
  bool _lobbyOverlay = false;

  // ──────────────────────────────────────────────────────────────────────────
  // Load
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> init() async {
    dlog('init', 'starting init for debateId=$debateId');
    emit(DebateConnectingState());
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
    _startLiveStatePolling();
    _isReady = true;
    dlog('init', 'init complete — isReady=true');
    emit(DebateConnectedState());
  }

  Future<void> _refreshLiveState() async {
    dlog('live-state', 'fetching live-state for debateId=$debateId');
    final res = await repo.getLiveState(debateId);
    res.fold(
      (f) {
        dlog('live-state', 'FETCH FAILED: ${f.message}');
        emit(DebateErrorState(f.message));
      },
      _applyLiveState,
    );
  }

  /// FE-10: start the ~10s live-state poll. Idempotent; runs for the whole
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

    // FV2-1: resolve the current speaker straight from live-state — the chair
    // never receives its own `stage_changed`, so this is its only way to know who
    // holds the floor. Prefer the server-resolved `speaker_user_id` (B3), falling
    // back to the participant→user mapping.
    _currentSpeakerUserId = _currentStage <= 0
        ? null
        : (stageEntry?.speakerUserId ??
            s.speakerByParticipantId(stageEntry?.participantId)?.user.id);
    _serverStartedAt = s.debate.currentStageStartedAt?.toUtc();

    final stageChanged = prevStage != _currentStage;

    // Timer is driven by the server's authoritative start time: it reads 0 in the
    // lobby (stage 0 → `current_stage_started_at` null) and only counts once a
    // speech has actually started — so it never runs "from open lobby" and never
    // auto-starts just because the chair joined/refreshed. We only (re)seed on an
    // actual stage change so a plain refresh never clobbers a running/paused clock
    // (e.g. after an open-lobby resume, where the server start time would wrongly
    // include the paused gap). Skipped entirely while the pause overlay is active.
    if (!_lobbyOverlay) {
      if (_currentStage <= 0) {
        _resetTimerSilently(); // lobby → 0, not counting
      } else if (stageChanged && isAuthority && _serverStartedAt != null) {
        // New speaking stage: the chair seeds from the server start (≈0 for a fresh
        // speech) and runs + broadcasts the clock. Non-authorities get the speaker
        // + clock from `stage_changed` / `time_update`, not from here.
        elapsedSeconds = DateTime.now()
            .toUtc()
            .difference(_serverStartedAt!)
            .inSeconds
            .clamp(0, 1 << 30);
        startTimer();
      }
    }

    if (stageChanged) {
      _clearPois(); // Issue 8: leftover POIs don't survive into the next speech
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
    if (s.debate.isCompleted) emit(DebateFinishedState());
    emit(LiveStateUpdatedState());
  }

  /// FE-9: when this device transitions to chair (re-derived from a fresh
  /// live-state / the FE-10 poll — no rejoin needed), re-broadcast the current
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
  // Rooms / connection (token discipline, §7)
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
      // Integrity check: the LiveKit identity must match the auth user we resolved
      // from the profile, or presence/role lookups (which key off the user id)
      // will silently fail. Log loudly instead of failing silently.
      if (identity != null && identity != _myUserId.toString()) {
        dlog(
          'connect',
          'WARN identity mismatch: LiveKit identity="$identity" but myUserId=$_myUserId '
              '— presence-by-userId may be off',
        );
      }

      localParticipant = _room!.localParticipant;
      await localParticipant?.setCameraEnabled(false);
      await localParticipant?.setMicrophoneEnabled(false);
      _startConnectionQualityTimer();
      _refreshParticipants();
      emit(DebateConnectedState());
      emit(LocalTrackUpdatedState());
      // The backend may elect/assign the chair as a side effect of the judge
      // JOINING the main room — which happens after our pre-join init() snapshot.
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
      // FV2-3: a remote mic/camera mute or unmute must refresh the cached
      // audio/video flags, else the tile shows a frozen frame / "not speaking"
      // instead of clearly muted / camera-off.
      ..on<TrackMutedEvent>((_) => _refreshParticipants())
      ..on<TrackUnmutedEvent>((_) => _refreshParticipants())
      // FE-3: dedicated join/leave trace (identity + new count) so a multi-device
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
    // Correct speaking detection for local + remote (§11.4).
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
  // Incoming backend events (§7)
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
        dlog('mode', 'debate_mode_started → entering debate from the open lobby');
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
        // FE-3: speeches done → result phase opens, status STILL live. Refresh so
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
        _signalResultNav(); // Issue 10: every device opens the shared result
        break;
      case LiveEventType.poiRaised:
        if (event.byUserId != null) {
          _poiRaisedUserIds.add(event.byUserId!);
          emit(POIChangedState());
        }
        break;
      case LiveEventType.poiAnswered:
        if (event.byUserId != null) _poiRaisedUserIds.remove(event.byUserId);
        emit(POIChangedState());
        break;
      case LiveEventType.timeUpdate:
        if (!isAuthority) _reconcileTime(event);
        break;
      case LiveEventType.timeControl:
        if (!isAuthority) {
          if (event.action == 'pause') pauseTimer();
          if (event.action == 'resume') startTimer();
        }
        break;
      case LiveEventType.lobbyOverlay:
        // Chair paused/resumed into the open-lobby grid (peer signal). Mirror the
        // overlay locally so this device switches view; the paired time_control
        // pause/resume freezes/continues the clock.
        dlog('mode', 'lobby_overlay received → ${event.lobbyOverlayEnabled}');
        _lobbyOverlay = event.lobbyOverlayEnabled;
        _clearPois(); // Issue 8: a toggle clears in-flight POIs
        emit(LobbyModeChangedState());
        break;
      case LiveEventType.teamChat:
        dlog('chat', 'TEAM CHAT received → team=${event.teamId} '
            'from=${event.senderName}: "${event.message}"');
        _chat.add(TeamChatMessage(
          teamId: event.teamId ?? '',
          senderId: event.senderId ?? '',
          senderName: event.senderName ?? '',
          message: event.message ?? '',
          ts: event.ts,
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
        dlog('moderation', 'room_closed received → tearing down the call UI (FE-7)');
        _roomClosed = true;
        emit(RoomClosedState());
        break;
    }
  }

  void _onStageChanged(LiveEvent e) {
    final previousStage = _currentStage;
    _clearPois(); // Issue 8: a new speech clears any leftover raised hands
    dlog('stage', 'stage_changed → currentStage=${e.currentStage} '
        'speakerUserId=${e.speakerUserId} serverStartedAt=${e.serverStartedAt} '
        'durationSeconds=${e.durationSeconds}');
    _currentStage = e.currentStage ?? _currentStage;
    _currentSpeakerUserId = e.speakerUserId;
    _serverStartedAt = DateTime.tryParse(e.serverStartedAt ?? '')?.toUtc();
    _rebuildTimeline(e.durationSeconds ?? _stageByOrder(_currentStage)?.durationSeconds);
    // Seed elapsed from the server start, then run the local timer (§7).
    final started = _serverStartedAt;
    elapsedSeconds = started == null
        ? 0
        : DateTime.now().toUtc().difference(started).inSeconds.clamp(0, 1 << 30);
    // FE-1: the lobby↔debate switch only rebuilds on LobbyModeChangedState, but a
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
  }

  void _reconcileTime(LiveEvent e) {
    final ts = DateTime.tryParse(e.timestamp ?? '')?.toUtc();
    final delay = ts == null ? 0 : DateTime.now().toUtc().difference(ts).inSeconds;
    final corrected = e.isPaused ? e.elapsedSeconds : e.elapsedSeconds + delay;
    if ((corrected - elapsedSeconds).abs() > kTimerSyncOffsetSeconds) {
      elapsedSeconds = corrected;
      isPaused = e.isPaused;
      emit(TimerTickedState());
    }
  }

  void _publish(List<int> bytes) {
    _logOutgoing(bytes);
    final lp = _room?.localParticipant;
    if (lp == null) {
      dlog('socket-send', 'DROPPED — not connected (localParticipant null)');
      return;
    }
    // §0.1 diagnostic: confirm the publish was accepted by the SFU. A throw here
    // is the tell-tale of a missing `canPublishData` grant (the V10 root cause) —
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
    _room?.localParticipant?.setMicrophoneEnabled(isMicEnabled);
    localAudioTrack = _localAudioTrack();
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
  // Timer (chair-broadcast, §7)
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
      if (isAuthority) {
        _publish(LiveDebateSocket.timeUpdate(
          elapsedSeconds: elapsedSeconds,
          isPaused: isPaused,
          timestamp: DateTime.now().toUtc(),
        ));
      }
    });
  }

  @override
  void pauseTimer() {
    isPaused = true;
    if (isAuthority) _publish(LiveDebateSocket.timeControl(pause: true));
    emit(TimerTickedState());
  }

  @override
  void resumeTimer() {
    if (isAuthority) _publish(LiveDebateSocket.timeControl(pause: false));
    startTimer();
  }

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
  // Stage flow (chair-driven, §7)
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
  void advanceDebate() {
    if (!isAuthority) {
      dlog('action', 'advanceDebate IGNORED — not authority (role=${_debateRole.wire})');
      return;
    }
    dlog('action', 'NEXT-STAGE ▸ POST next-stage (currentStage=$_currentStage, '
        'isLastStep=$isLastStep)');
    repo.nextStage(debateId).then((res) => res.fold(
          (f) {
            dlog('action', 'next-stage FAILED: ${f.message}');
            emit(DebateErrorState(f.message));
          },
          (_) {
            dlog('action', 'next-stage OK — refreshing live-state (FE-1 safety net)');
            _refreshLiveState();
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

  /// FE-7: drive the fixed slot count from the backend format's `speakers_per_side`.
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
  // POI (best-effort mapping to the test-shaped widgets, §7)
  // ──────────────────────────────────────────────────────────────────────────

  int? get _currentPhaseId => _stageByOrder(_currentStage)?.id;

  @override
  void sendPOIRequest() {
    isLocalAskingPOI = true;
    _poiRaisedUserIds.add(_myUserId);
    final phaseId = _currentPhaseId;
    dlog('poi', 'POI raised by me (userId=$_myUserId, phaseId=$phaseId)');
    // FE-4: ALWAYS broadcast the peer flash so every other device shows the POI,
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
    // FE-5: answer the SPECIFIC asker (by user id) so two simultaneous askers are
    // disambiguated — clear only that asker and tell every device to drop that
    // asker's badge (`by_user_id` = the asker being answered).
    final askerId = int.tryParse(askerUserId);
    dlog('poi', 'POI accepted (asker=$askerUserId, phaseId=$phaseId)');
    // FE-4: always broadcast the answer flash; only persistence needs the phase id.
    _publish(LiveDebateSocket.poiAnswered(
        stagePhaseId: phaseId, byUserId: askerId ?? _myUserId));
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
    // FE-5: dismiss only the specific asker's badge.
    final uid = int.tryParse(askerUserId);
    if (uid != null) _poiRaisedUserIds.remove(uid);
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

  /// Issue 8: drop all in-flight POIs — called on a stage change and on an
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

  /// The open lobby is shown either before/after the debate (real stage 0) or
  /// during a chair PAUSE overlay mid-debate.
  @override
  bool get isLobbyMode => _currentStage <= 0 || _lobbyOverlay || resultPhaseOpen;

  /// Chair toggle. Mid-debate it's a **pause overlay** that freezes the current
  /// speaker + clock (so resume continues from the same spot, never restarting or
  /// counting during the break). At stage 0 it starts/advances the debate.
  @override
  void setLobbyMode(bool enabled) {
    if (!isAuthority) {
      dlog('action', 'setLobbyMode IGNORED — not authority');
      return;
    }
    // Issue 9: once the speeches are done (result phase open) the room stays in
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
        _clearPois(); // Issue 8: clear in-flight POIs on the toggle
        pauseTimer(); // freezes elapsed + broadcasts time_control pause
        _publish(LiveDebateSocket.lobbyOverlay(enabled: true));
        emit(LobbyModeChangedState());
      }
    } else if (_lobbyOverlay) {
      // Resume the paused speaker exactly where they stopped.
      dlog('action', 'OPEN-LOBBY resume ▸ continue stage $_currentStage '
          '(elapsed=$elapsedSeconds)');
      _lobbyOverlay = false;
      _publish(LiveDebateSocket.lobbyOverlay(enabled: false));
      resumeTimer(); // continues from the frozen elapsed + broadcasts resume
      emit(LobbyModeChangedState());
    } else {
      // Real stage-0 lobby → start / advance the debate.
      dlog('action', 'START/NEXT ▸ POST next-stage (from stage $_currentStage)');
      repo.nextStage(debateId).then((res) => res.fold(
            (f) {
              dlog('action', 'next-stage FAILED: ${f.message}');
              emit(DebateErrorState(f.message));
            },
            (_) {
              dlog('action', 'next-stage OK — refreshing live-state (FE-1 safety net)');
              _refreshLiveState();
            },
          ));
    }
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

  // ── Durable publish-lock (mic + camera), chair-broadcast (§FE-4/FE-6) ────────
  // Mirrors the mock's design: "mute all" / per-user lock *prevents opening* the
  // mic/camera (not just a one-off mute). Judges + whoever holds the floor are
  // always exempt. The chair broadcasts the lock; each client enforces it on
  // itself in [_enforcePublishLock] (forcing its own track off if it just lost
  // permission), so it works without LiveKit server APIs (client-cooperative).

  bool _isUserExempt(int uid) =>
      (_state?.isJudge(uid) ?? false) || _currentSpeakerUserId == uid;

  /// Judges + the current main speaker can always publish (never locked).
  bool get _amExemptFromLock =>
      _debateRole.isJudge || _iAmCurrentSpeaker;

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
    if (_amExemptFromLock) return true;
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
    ));
    _publish(LiveDebateSocket.teamChat(
      teamId: teamId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      ts: ts,
    ));
    emit(TeamChatUpdatedState());
  }

  @override
  List<TeamChatMessage> chatFor(String viewerTeamId) =>
      _chat.where((m) => m.teamId == viewerTeamId).toList();

  // ──────────────────────────────────────────────────────────────────────────
  // Role → controls gating (§8)
  // ──────────────────────────────────────────────────────────────────────────

  bool get _iAmCurrentSpeaker => _currentSpeakerUserId == _myUserId;

  /// Issue 8: only the real current speaker may answer a POI. In the lobby
  /// `_currentSpeakerUserId` is null → false for everyone.
  @override
  bool get iAmCurrentSpeaker => _iAmCurrentSpeaker;

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
  @override
  bool get canUseMedia => isLobbyMode || !isSpectator;
  @override
  bool get canAskPoi => _debateRole.isDebater;
  @override
  bool get poiEnabledNow {
    final slot = currentSlot;
    return canAskPoi && poiOpen && slot != null && slot.side != localSide;
  }

  @override
  bool get canOpenChat =>
      _debateRole.isDebater && !_iAmCurrentSpeaker;

  // ──────────────────────────────────────────────────────────────────────────
  // Result flow (§10) — REST actions; state read from live-state
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

  /// FE-3: result phase is open while the debate is still `live` — driven by the
  /// backend's `speeches_completed_at` / `rooms.result.open` (B1), never by
  /// `status == completed`.
  @override
  bool get resultPhaseOpen =>
      (_state?.debate.speechesCompleted ?? false) ||
      (_state?.rooms.result.open ?? false) ||
      debateFinished;

  /// FE-6: a result has been stored (chair post-submit / judges) — gates the
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
        // FE-1: the backend requires an INTEGER 0–100 per stage — round defensively
        // so a stray double can never trip the `must be an integer` validator.
        for (final e in scoresByStageOrder.entries)
          StageScore(stageOrder: e.key, score: e.value.round()),
      ],
    );
    dlog('action', 'SUBMIT RESULT ▸ POST result (winner=${winningSide.name}, '
        'stages=${scoresByStageOrder.length})');
    final res = await repo.submitResult(debateId: debateId, result: model);
    // FE-1: report the REAL outcome so the sheet never lies about success.
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
        // Reveals an existing result (no confetti) or cancels the debate (§10).
        await _refreshLiveState();
        if (isCancelled) emit(DebateCancelledState());
      },
    );
  }

  // ── Share result / close room (§U4b) — backend stubs ────────────────────────
  // The dedicated endpoints (server-side publish-lock, kick-all, explicit
  // live→done) don't exist yet; map to what we have and TODO the rest.

  /// Issue 10: navigate to the shared result exactly once (idempotent), driven
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

  @override
  bool get isRoomClosed => _roomClosed;

  /// Chair: force-close the room (FE-7). The backend reveals a pending result or
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
  Future<void> sendDebateRating(int rating) async {
    final res = await repo.sendFeedback(
      debateId: debateId,
      type: 'rating_debate',
      rating: rating,
    );
    res.fold(
          (f) => emit(DebateErrorState(f.message)),
          (_) => emit(LiveStateUpdatedState()),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> disconnect() async {
    dlog('leave', 'LEAVE ▸ local user leaving the room (userId=$_myUserId)');
    _stopLiveStatePolling();
    await _room?.disconnect();
    await _roomEvents?.dispose();
    _connectionQualityTimer?.cancel();
    _localTimer?.cancel();
    _poiTimer?.cancel();
    emit(DebateDisconnectedState(reason: 'User left the debate'));
  }

  @override
  Future<void> close() async {
    _stopLiveStatePolling();
    await _room?.dispose();
    await _roomEvents?.dispose();
    _connectionQualityTimer?.cancel();
    _localTimer?.cancel();
    _poiTimer?.cancel();
    return super.close();
  }
}