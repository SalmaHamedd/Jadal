import 'dart:async';

import 'package:livekit_client/livekit_client.dart';

import '../../data/datasources/mock_live_debate_data.dart';
import '../../data/debate_socket_protocol.dart';
import '../../data/models/debate_models.dart';
import '../../debate_test_credentials.dart';
import '../../domain/debate_result_view.dart';
import '../utils/debate_log.dart';
import '../utils/debate_timeline.dart';
import 'debate_controller.dart';

/// Test/mock live-debate controller (§1/§9): peer-to-peer over a LiveKit data
/// channel with no backend. The local user is the authority and broadcasts
/// everything itself. Implements [DebateController] so the shared widget set
/// renders it identically to the backend [LiveDebateCubit].
class DebateCubit extends DebateController {
  DebateCubit({required this.data}) : super(DebateInitialState()) {
    timeline = DebateTimeline(data.format);
    _buildSequence();
    _seedOrders();
  }

  @override
  final MockLiveDebateData data;
  @override
  late final DebateTimeline timeline;

  // ── LiveKit ────────────────────────────────────────────────────────────────
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

  @override
  double get localAudioLevel => _room?.localParticipant?.audioLevel ?? 0;

  // ── Timer ──────────────────────────────────────────────────────────────────
  @override
  int elapsedSeconds = 0;
  @override
  bool isPaused = true;
  Timer? _localTimer;
  Timer? _connectionQualityTimer;

  /// In test mode the local user is the active speaker → authority.
  @override
  bool get isAuthority => true;

  // ── Debate flow ──────────────────────────────────────────────────────────
  final List<SpeechSlot> _sequence = [];
  int _currentStep = -1; // -1 = not started
  @override
  bool debateStarted = false;
  @override
  bool debateFinished = false;

  /// In test mode the local user represents the proposition's first speaker.
  @override
  DebateSide get localSide => DebateSide.proposition;

  @override
  SpeechSlot? get currentSlot =>
      (_currentStep >= 0 && _currentStep < _sequence.length) ? _sequence[_currentStep] : null;

  @override
  DebateSide get currentSpeakerSide => currentSlot?.side ?? DebateSide.proposition;

  // ── POI ──────────────────────────────────────────────────────────────────
  final Set<String> _askingPoiSids = {};
  @override
  bool isLocalAskingPOI = false;
  @override
  bool localPoiAccepted = false; // asker may open mic (shows the mic dialog)
  Timer? _poiTimer;

  // ── News ───────────────────────────────────────────────────────────────────
  @override
  String latestNews = '';
  int _newsCounter = 1;

  // ── Speaker order ────────────────────────────────────────────────────────
  @override
  late SpeakerOrder propOrder;
  @override
  late SpeakerOrder oppOrder;

  // ── Lobby mode + chat ──────────────────────────────────────────────────────
  @override
  bool isLobbyMode = false;
  final List<TeamChatMessage> _chat = [];
  @override
  List<TeamChatMessage> get chatMessages => List.unmodifiable(_chat);

  // ── Result (§10) ─────────────────────────────────────────────────────────────
  // Test mode keeps the result locally — there's no backend to submit to.
  DebateSide? _winningSide;
  String _resultNotes = '';
  final Map<int, num> _stageScores = {}; // 1-based stage order → score
  bool _resultSubmitted = false;
  bool _resultRevealed = false;
  bool _cancelled = false;

  // Moderation publish-lock (mic + camera) + share/close (§U4b).
  bool _muteAllActive = false;
  bool _cameraAllOff = false;
  final Set<String> _publishLockedIds = {};
  final Set<String> _cameraLockedIds = {};
  bool _resultShared = false;
  bool _roomClosed = false;

  // ── Role → controls gating (§8) ─────────────────────────────────────────────
  // Test mode shows everything so the tester can exercise every feature.
  @override
  bool get canModerateOthers => true;
  @override
  bool get canControlStage => true;
  @override
  bool get canControlTimer => true;
  @override
  bool get canManageResult => true;
  @override
  bool get canUseMedia => true;
  @override
  bool get canAskPoi => true;
  // §9.1 applies in both modes: the POI button follows the open window. Test
  // mode ignores the opposing-side rule (it's a solo demo) but still respects
  // the protected/open windows so they're exercisable.
  @override
  bool get poiEnabledNow => poiOpen;
  @override
  bool get canOpenChat => true;
  @override
  bool get isSpectator => false;

  /// Test entry (§9): connect with the pasted LiveKit creds (if any) and start
  /// as the first speaker so the full timer state machine runs.
  @override
  Future<void> enterDebateRoom() async {
    if (kHasLiveKitCredentials) {
      await connectToRoom(url: kLiveKitUrl, token: kLiveKitToken);
    } else {
      // No real room in pure mock mode — signal "ready" so the room screen's
      // connection gate shows the debate instead of hanging on a spinner.
      emit(DebateConnectedState());
    }
    startAsFirstSpeaker();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Setup
  // ──────────────────────────────────────────────────────────────────────────

  void _buildSequence() {
    _sequence
      ..clear()
      // Substantive speeches alternate prop/opp for the three speakers.
      ..add(const SpeechSlot(side: DebateSide.proposition, orderIndex: 0))
      ..add(const SpeechSlot(side: DebateSide.opposition, orderIndex: 0))
      ..add(const SpeechSlot(side: DebateSide.proposition, orderIndex: 1))
      ..add(const SpeechSlot(side: DebateSide.opposition, orderIndex: 1))
      ..add(const SpeechSlot(side: DebateSide.proposition, orderIndex: 2))
      ..add(const SpeechSlot(side: DebateSide.opposition, orderIndex: 2));
    if (data.format.replySpeech) {
      // Reply speeches: opposition first, then proposition (WSDC convention).
      _sequence
        ..add(const SpeechSlot(side: DebateSide.opposition, orderIndex: 0, isReply: true))
        ..add(const SpeechSlot(side: DebateSide.proposition, orderIndex: 0, isReply: true));
    }
  }

  void _seedOrders() {
    // Default order = the team's roster order; not yet "set" by a leader.
    propOrder = SpeakerOrder(
      orderedSpeakerIds: data.propositionTeam.debaters.map((d) => d.id).toList(),
      isSet: false,
    );
    oppOrder = SpeakerOrder(
      orderedSpeakerIds: data.oppositionTeam.debaters.map((d) => d.id).toList(),
      isSet: false,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Connection
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> connectToRoom({required String url, required String token}) async {
    emit(DebateConnectingState());

    try {
      await _room?.disconnect();
      await _roomEvents?.dispose();

      _room = Room(roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
      _roomEvents = _room!.createListener();
      _registerRoomListeners();

      dlog('connect(mock)', 'ATTEMPTING connect to $url');
      await _room!.connect(url, token);
      dlog(
        'connect(mock)',
        'CONNECT SUCCEEDED — localIdentity=${_room!.localParticipant?.identity} | '
            'remoteParticipants=${_room!.remoteParticipants.length}',
      );

      localParticipant = _room!.localParticipant;
      await localParticipant?.setCameraEnabled(false);
      await localParticipant?.setMicrophoneEnabled(false);
      _startConnectionQualityTimer();
      emit(DebateConnectedState());
      emit(LocalTrackUpdatedState());
    } catch (e, stack) {
      dlog('connect(mock)', 'CONNECT FAILED: $e');
      dlog('connect(mock)', stack.toString());
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
          isLocalSpeaking = false;
          emit(LocalTrackUpdatedState());
        }
      })
      ..on<TrackSubscribedEvent>((_) => _refreshParticipants())
      ..on<TrackUnsubscribedEvent>((_) => _refreshParticipants())
      // A remote mute/unmute must refresh the cached mic/camera flags (FV2-3).
      ..on<TrackMutedEvent>((_) => _refreshParticipants())
      ..on<TrackUnmutedEvent>((_) => _refreshParticipants())
      ..on<ParticipantConnectedEvent>((_) => _refreshParticipants())
      ..on<ParticipantDisconnectedEvent>((event) {
        _askingPoiSids.remove(event.participant.sid);
        _refreshParticipants();
      })
      // Speaking detection is mic-only and reliable via the active-speakers
      // event (§11.4) — the old per-frame audioLevel threshold never fired.
      ..on<ActiveSpeakersChangedEvent>((event) {
        final speakerSids = event.speakers.map((s) => s.sid).toSet();
        isLocalSpeaking =
            localParticipant != null && speakerSids.contains(localParticipant!.sid);
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
    // Speaking state is owned by the ActiveSpeakersChangedEvent listener.
    final tmp = <RemoteParticipant>[];
    for (final p in _room!.remoteParticipants.values) {
      tmp.add(p);
      _remoteHasAudio[p.sid] = _remoteMicOn(p);
      _remoteHasVideo[p.sid] = _remoteCameraOn(p);
    }
    participants = tmp;
    emit(RemoteTrackReceivedState());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Incoming data-channel messages (§6)
  // ──────────────────────────────────────────────────────────────────────────

  void _onData(List<int> bytes) {
    final event = DebateSocketProtocol.decode(bytes);
    if (event == null) return;
    switch (event.type) {
      case DebateEventType.poiRequest:
        if (event.sid != null) {
          _askingPoiSids.add(event.sid!);
          emit(POIChangedState());
        }
        break;
      case DebateEventType.poiAccepted:
        if (event.targetSid == localParticipant?.sid) {
          localPoiAccepted = true;
          isLocalAskingPOI = false;
          emit(POIAcceptedForLocalState());
        }
        break;
      case DebateEventType.poiDone:
        if (event.sid != null) {
          _askingPoiSids.remove(event.sid);
          emit(POIChangedState());
        }
        break;
      case DebateEventType.newsUpdate:
        if (event.message != null) {
          latestNews = event.message!;
          emit(NewsUpdatedState());
        }
        break;
      case DebateEventType.timeUpdate:
        if (!isAuthority) {
          final elapsed = event.elapsedSeconds;
          final ts = DateTime.tryParse(event.timestamp ?? '')?.toUtc();
          final delay = ts == null ? 0 : DateTime.now().toUtc().difference(ts).inSeconds;
          final corrected = event.isPaused ? elapsed : elapsed + delay;
          if ((corrected - elapsedSeconds).abs() > 2) {
            elapsedSeconds = corrected;
            isPaused = event.isPaused;
            emit(TimerTickedState());
          }
        }
        break;
      case DebateEventType.timeControl:
        if (!isAuthority) {
          if (event.action == 'pause') pauseTimer();
          if (event.action == 'resume') startTimer();
        }
        break;
      case DebateEventType.speakerState:
        emit(SpeakerChangedState());
        break;
      case DebateEventType.speakerOrderUpdate:
        _applyRemoteOrder(event);
        break;
      case DebateEventType.forceMute:
        if (event.targetSid == localParticipant?.sid && isMicEnabled) {
          toggleMic();
        }
        break;
      case DebateEventType.forceCameraOff:
        if (event.targetSid == localParticipant?.sid && isCameraEnabled) {
          toggleCamera();
        }
        break;
      case DebateEventType.teamChat:
        _chat.add(TeamChatMessage(
          teamId: event.teamId ?? '',
          senderId: event.senderId ?? '',
          senderName: event.senderName ?? '',
          message: event.message ?? '',
          ts: event.ts,
        ));
        emit(TeamChatUpdatedState());
        break;
      case DebateEventType.lobbyMode:
        isLobbyMode = event.enabled;
        emit(LobbyModeChangedState());
        break;
      case DebateEventType.publishLock:
        _muteAllActive = event.muteAll;
        _cameraAllOff = event.cameraAllOff;
        _publishLockedIds
          ..clear()
          ..addAll(event.lockedIds);
        _cameraLockedIds
          ..clear()
          ..addAll(event.cameraLockedIds);
        _enforcePublishLock();
        emit(PublishLockChangedState());
        break;
      case DebateEventType.shareResult:
        _resultRevealed = true;
        _resultShared = true;
        emit(NavigateToSharedResultState());
        break;
      case DebateEventType.closeRoom:
        _roomClosed = true;
        emit(RoomClosedState());
        break;
    }
  }

  void _applyRemoteOrder(DebateEvent event) {
    final order = SpeakerOrder(
      orderedSpeakerIds: event.orderedSpeakerIds,
      replySpeakerId: event.replySpeakerId,
      isSet: true,
    );
    if (event.teamId == data.propositionTeam.teamId) {
      propOrder = order;
    } else if (event.teamId == data.oppositionTeam.teamId) {
      oppOrder = order;
    }
    emit(SpeakerOrderChangedState());
  }

  void _publish(List<int> bytes) {
    _room?.localParticipant
        ?.publishData(bytes, reliable: true, topic: DebateSocketProtocol.topic);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Local media
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void toggleMic() {
    isMicEnabled = !isMicEnabled;
    _room?.localParticipant?.setMicrophoneEnabled(isMicEnabled);
    localAudioTrack = _localAudioTrack();
    emit(MicToggledState());
    emit(LocalTrackUpdatedState());
  }

  @override
  void toggleCamera() {
    isCameraEnabled = !isCameraEnabled;
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
  // Timer + timeline (§8.3 B)
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
      if (isAuthority) _broadcastTime();
    });
  }

  @override
  void pauseTimer() {
    isPaused = true;
    if (isAuthority) _publish(DebateSocketProtocol.timeControl(pause: true));
    emit(TimerTickedState());
  }

  @override
  void resumeTimer() {
    if (isAuthority) _publish(DebateSocketProtocol.timeControl(pause: false));
    startTimer();
  }

  @override
  void resetTimer() {
    elapsedSeconds = 0;
    isPaused = true;
    _localTimer?.cancel();
    emit(TimerTickedState());
  }

  void _broadcastTime() {
    _publish(DebateSocketProtocol.timeUpdate(
      elapsedSeconds: elapsedSeconds,
      isPaused: isPaused,
      timestamp: DateTime.now().toUtc(),
    ));
  }

  @override
  DebateTier get currentTier =>
      timeline.tierAt(elapsedSeconds, isReply: currentSlot?.isReply ?? false);
  @override
  bool get poiOpen =>
      timeline.poiOpenAt(elapsedSeconds, isReply: currentSlot?.isReply ?? false) &&
      currentSlot != null;

  // ──────────────────────────────────────────────────────────────────────────
  // Debate flow (next-state button, §8.6)
  // ──────────────────────────────────────────────────────────────────────────

  /// Whether the next press marks the debate done (after the last speech).
  @override
  bool get isLastStep => _currentStep >= _sequence.length - 1;

  /// Start → next speaker → mark done. In test mode the local user remains the
  /// active speaker; only the role slot advances (§9).
  @override
  void advanceDebate() {
    if (debateFinished) return;
    if (!debateStarted) {
      debateStarted = true;
      _currentStep = 0;
      _startCurrentSpeech();
      return;
    }
    if (isLastStep) {
      markDebateDone();
      return;
    }
    _currentStep++;
    _startCurrentSpeech();
  }

  void _startCurrentSpeech() {
    resetTimer();
    startTimer();
    final slot = currentSlot!;
    _publish(DebateSocketProtocol.speakerState(
      speakerSid: localParticipant?.sid ?? 'local',
      role: roleLabelForSlot(slot),
      side: slot.side.name,
      index: slot.orderIndex,
    ));
    emit(SpeakerChangedState());
    // Ticks begin at 1s, so fire the 0:00 "speech starts / opening protected"
    // boundary (and its bell) explicitly.
    emit(DebateTimelineEventState(DebateTimelineEvent.speechStarted));
  }

  /// Entry helper for test mode (§9): treat the local user as the first speaker
  /// and start the timer immediately.
  @override
  void startAsFirstSpeaker() {
    if (!debateStarted) advanceDebate();
  }

  /// Marks the debate done — unlocks the Result room and is the chair's
  /// "finish" action (§8.6).
  @override
  void markDebateDone() {
    debateFinished = true;
    isPaused = true;
    _localTimer?.cancel();
    // After the last speaker the room defaults to the open lobby — there's no
    // going back to the live-debate layout (§U4b).
    isLobbyMode = true;
    _publish(DebateSocketProtocol.lobbyMode(enabled: true));
    emit(LobbyModeChangedState());
    emit(DebateFinishedState());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Speaker resolution helpers (used by the speakers section)
  // ──────────────────────────────────────────────────────────────────────────

  @override
  TeamInfo teamFor(DebateSide side) =>
      side == DebateSide.proposition ? data.propositionTeam : data.oppositionTeam;

  @override
  SpeakerOrder orderFor(DebateSide side) =>
      side == DebateSide.proposition ? propOrder : oppOrder;

  /// The debater speaking in [side]'s slot [orderIndex], following the order if
  /// set, else the roster order.
  @override
  Debater debaterAt(DebateSide side, int orderIndex) {
    final team = teamFor(side);
    final order = orderFor(side);
    if (order.orderedSpeakerIds.length > orderIndex) {
      final id = order.orderedSpeakerIds[orderIndex];
      final d = team.debaterById(id);
      if (d != null) return d;
    }
    return team.debaters[orderIndex];
  }

  /// Card label: P1/O2/etc., with reply suffix (e.g. `P2 - PR`) when this slot
  /// is also the side's reply speaker (§4).
  @override
  String roleLabel(DebateSide side, int orderIndex) {
    final base = '${side.rolePrefix}${orderIndex + 1}';
    final order = orderFor(side);
    if (data.format.replySpeech &&
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

  /// Whether [side]/[orderIndex] is the speaker currently holding the floor.
  @override
  bool isCurrentSpeaker(DebateSide side, int orderIndex) {
    final slot = currentSlot;
    if (slot == null) return false;
    return slot.side == side && slot.orderIndex == orderIndex;
  }

  @override
  bool isAskingPOIByDebater(String debaterId) {
    // In test mode the local user maps to the active proposition speaker.
    if (isLocalAskingPOI && debaterId == debaterAt(localSide, 0).id) return true;
    return false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // POI (§8.4)
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void sendPOIRequest() {
    isLocalAskingPOI = true;
    _publish(DebateSocketProtocol.poiRequest(localParticipant?.sid ?? 'local'));
    emit(POIChangedState());
    _poiTimer?.cancel();
    _poiTimer = Timer(const Duration(seconds: 15), () {
      isLocalAskingPOI = false;
      if (!isClosed) emit(POIChangedState());
    });
  }

  /// Speaker accepts a POI → asker may open their mic.
  @override
  void acceptPOI(String askerSid) {
    _askingPoiSids.remove(askerSid);
    _publish(DebateSocketProtocol.poiAccepted(askerSid));
    // LiveKit doesn't loop data back to the sender, so in solo test mode the
    // local asker would never see the accept. Surface it directly when the
    // accepted asker is the local user.
    if (askerSid == (localParticipant?.sid ?? 'local')) {
      localPoiAccepted = true;
      isLocalAskingPOI = false;
      emit(POIAcceptedForLocalState());
    }
    emit(POIChangedState());
  }

  /// Speaker refuses a POI (also used by swipe-down-to-refuse).
  @override
  void refusePOI(String askerSid) {
    _askingPoiSids.remove(askerSid);
    if (askerSid == localParticipant?.sid) isLocalAskingPOI = false;
    emit(POIChangedState());
  }

  /// Asker finished their POI → return to silence.
  @override
  void poiDone() {
    localPoiAccepted = false;
    _publish(DebateSocketProtocol.poiDone(localParticipant?.sid ?? 'local'));
    if (isMicEnabled) toggleMic();
    emit(POIChangedState());
  }

  @override
  bool isAskingPOIBySid(String sid) => _askingPoiSids.contains(sid);
  @override
  Set<String> get askingPoiSids => Set.unmodifiable(_askingPoiSids);

  /// Identities currently present, used for leader/chair resolution (§8.1).
  /// In solo test mode this is just the mock [MockLiveDebateData.currentUserId].
  @override
  Set<String> get presentIds {
    final ids = <String>{data.currentUserId};
    final localId = localParticipant?.identity;
    if (localId != null && localId.isNotEmpty) ids.add(localId);
    for (final p in participants) {
      if (p.identity.isNotEmpty) ids.add(p.identity);
    }
    return ids;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // News (§8.3 / §8.6)
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void updateLatestNews(String message) {
    latestNews = message;
    _publish(DebateSocketProtocol.newsUpdate(message));
    emit(NewsUpdatedState());
  }

  /// Test action: pushes a random news message (§8.6).
  @override
  void pushRandomNews(String Function(int n) build) =>
      updateLatestNews(build(_newsCounter++));

  // ──────────────────────────────────────────────────────────────────────────
  // Speaker order (§8.1)
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void setSpeakerOrder({
    required String teamId,
    required List<String> orderedSpeakerIds,
    String? replySpeakerId,
  }) {
    final order = SpeakerOrder(
      orderedSpeakerIds: orderedSpeakerIds,
      replySpeakerId: replySpeakerId,
      isSet: true,
    );
    if (teamId == data.propositionTeam.teamId) {
      propOrder = order;
    } else if (teamId == data.oppositionTeam.teamId) {
      oppOrder = order;
    }
    _publish(DebateSocketProtocol.speakerOrderUpdate(
      teamId: teamId,
      orderedSpeakerIds: orderedSpeakerIds,
      replySpeakerId: replySpeakerId,
    ));
    emit(SpeakerOrderChangedState());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Lobby mode, mute-all, chat (§8.5)
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void setLobbyMode(bool enabled) {
    isLobbyMode = enabled;
    _publish(DebateSocketProtocol.lobbyMode(enabled: enabled));
    emit(LobbyModeChangedState());
  }

  @override
  void muteAll() {
    for (final p in participants) {
      _publish(DebateSocketProtocol.forceMute(p.sid));
    }
    emit(POIChangedState());
  }

  @override
  void forceCameraOff(String targetSid) =>
      _publish(DebateSocketProtocol.forceCameraOff(targetSid));

  // ── Publish-lock moderation (§U4b) ───────────────────────────────────────────
  // "Mute all" / per-user lock prevents *opening* the mic (not just turning it
  // off); judges and the current main speaker are always exempt. The final
  // decision to actually open the mic stays with each (non-locked) user.

  @override
  bool get muteAllActive => _muteAllActive;

  @override
  Set<String> get publishLockedIds => Set.unmodifiable(_publishLockedIds);

  /// Judges + whoever currently holds the floor can always publish.
  bool get _amExemptFromLock {
    final myId = data.currentUserId;
    if (data.judges.any((j) => j.id == myId)) return true;
    final slot = currentSlot;
    return slot != null && debaterAt(slot.side, slot.orderIndex).id == myId;
  }

  @override
  bool get canPublishNow {
    if (_amExemptFromLock) return true;
    if (_muteAllActive) return false;
    return !_publishLockedIds.contains(data.currentUserId);
  }

  @override
  bool get cameraAllOff => _cameraAllOff;

  @override
  Set<String> get cameraLockedIds => Set.unmodifiable(_cameraLockedIds);

  @override
  bool get canEnableCameraNow {
    if (_amExemptFromLock) return true;
    if (_cameraAllOff) return false;
    return !_cameraLockedIds.contains(data.currentUserId);
  }

  @override
  void toggleMuteAll() {
    _muteAllActive = !_muteAllActive;
    _broadcastPublishLock();
    _enforcePublishLock();
    emit(PublishLockChangedState());
  }

  @override
  void toggleCameraAll() {
    _cameraAllOff = !_cameraAllOff;
    _broadcastPublishLock();
    _enforcePublishLock();
    emit(PublishLockChangedState());
  }

  @override
  void toggleUserPublishLock(String userId) {
    if (!_publishLockedIds.add(userId)) _publishLockedIds.remove(userId);
    _broadcastPublishLock();
    _enforcePublishLock();
    emit(PublishLockChangedState());
  }

  @override
  void toggleUserCameraLock(String userId) {
    if (!_cameraLockedIds.add(userId)) _cameraLockedIds.remove(userId);
    _broadcastPublishLock();
    _enforcePublishLock();
    emit(PublishLockChangedState());
  }

  void _broadcastPublishLock() => _publish(DebateSocketProtocol.publishLock(
        muteAll: _muteAllActive,
        lockedIds: _publishLockedIds.toList(),
        cameraAllOff: _cameraAllOff,
        cameraLockedIds: _cameraLockedIds.toList(),
      ));

  /// If the local user just lost mic/camera permission, force the track off.
  void _enforcePublishLock() {
    if (!canPublishNow && isMicEnabled) toggleMic();
    if (!canEnableCameraNow && isCameraEnabled) toggleCamera();
  }

  /// Per-user moderation entry (participant dialog): toggles their publish lock.
  @override
  void forceMute(String targetSid) => toggleUserPublishLock(targetSid);

  /// Sends a team-chat message visible only to same-team participants.
  @override
  void sendTeamChat({required String teamId, required String message}) {
    final senderName = localParticipant?.name.isNotEmpty == true
        ? localParticipant!.name
        : firstName(data.propositionTeam.debaters.first.name);
    final senderId = localParticipant?.identity ?? data.currentUserId;
    final ts = DateTime.now().millisecondsSinceEpoch;
    _chat.add(TeamChatMessage(
      teamId: teamId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      ts: ts,
    ));
    _publish(DebateSocketProtocol.teamChat(
      teamId: teamId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      ts: ts,
    ));
    emit(TeamChatUpdatedState());
  }

  /// Messages visible to a viewer on [viewerTeamId] (same-team only, §8.5).
  @override
  List<TeamChatMessage> chatFor(String viewerTeamId) =>
      _chat.where((m) => m.teamId == viewerTeamId).toList();

  // ──────────────────────────────────────────────────────────────────────────
  // Result flow (§10) — local, no backend
  // ──────────────────────────────────────────────────────────────────────────

  /// The full speech sequence (substantive + reply) as scoreable stages.
  @override
  List<ResultStageRef> get scoreableStages => [
        for (var i = 0; i < _sequence.length; i++)
          ResultStageRef(
            stageOrder: i + 1,
            roleLabel: roleLabelForSlot(_sequence[i]),
            speakerName: debaterAt(_sequence[i].side, _sequence[i].orderIndex).name,
            side: _sequence[i].side,
            isReply: _sequence[i].isReply,
          ),
      ];

  @override
  bool get isCancelled => _cancelled;

  @override
  DebateResultView? get resultView {
    if (!_resultSubmitted) return null;
    final speeches = [
      for (final st in scoreableStages)
        ResultSpeechScore(
          stageOrder: st.stageOrder,
          roleLabel: st.roleLabel,
          speakerName: st.speakerName,
          side: st.side,
          isReply: st.isReply,
          score: _stageScores[st.stageOrder],
        ),
    ];
    final winner = _winningSide;
    return DebateResultView(
      winningSide: winner,
      winningTeamName: winner == null ? null : teamFor(winner).teamName,
      losingTeamName: winner == null ? null : teamFor(winner.other).teamName,
      summaryNotes: _resultNotes,
      speeches: speeches,
      revealed: _resultRevealed,
    );
  }

  @override
  Future<bool> submitResult({
    required DebateSide winningSide,
    required Map<int, num> scoresByStageOrder,
    required String summaryNotes,
  }) async {
    _winningSide = winningSide;
    _stageScores
      ..clear()
      ..addAll(scoresByStageOrder);
    _resultNotes = summaryNotes;
    _resultSubmitted = true;
    emit(LiveStateUpdatedState());
    return true; // FE-1: local test mode always succeeds
  }

  @override
  Future<void> revealResult() async {
    if (!_resultSubmitted) return;
    _resultRevealed = true;
    emit(ResultRevealedState()); // confetti
  }

  @override
  Future<void> closeMain() async {
    if (_resultSubmitted) {
      // A result exists → auto-reveal, but without the confetti (§10).
      _resultRevealed = true;
      emit(LiveStateUpdatedState());
    } else {
      _cancelled = true;
      emit(DebateCancelledState());
    }
  }

  // ── Share result / close room from the live room (§U4b) ──────────────────────

  @override
  bool get resultShared => _resultShared;

  @override
  bool get isRoomClosed => _roomClosed;

  /// Chair: reveal + push the result to everyone (confetti) and move to done /
  /// open-lobby. In a real backend this also flips the stage live→done.
  @override
  Future<void> shareResult() async {
    if (!_resultSubmitted) return;
    _resultRevealed = true;
    _resultShared = true;
    debateFinished = true;
    // Back from the result screen lands everyone in the live open lobby (§U4b).
    isLobbyMode = true;
    _publish(DebateSocketProtocol.lobbyMode(enabled: true));
    _publish(DebateSocketProtocol.shareResult());
    emit(NavigateToSharedResultState());
  }

  /// Chair: close the room — everyone is kicked back to the rooms list and the
  /// live-debate join is locked.
  @override
  Future<void> closeRoom() async {
    _roomClosed = true;
    _publish(DebateSocketProtocol.closeRoom());
    emit(RoomClosedState());
  }

  @override
  Future<void> sendDebateRating(int rating) async {
    // No backend in test mode; the UI shows a local "thanks" acknowledgement.
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> disconnect() async {
    await _room?.disconnect();
    await _roomEvents?.dispose();
    _connectionQualityTimer?.cancel();
    _localTimer?.cancel();
    _poiTimer?.cancel();
    emit(DebateDisconnectedState(reason: 'User left the debate'));
  }

  @override
  Future<void> close() async {
    await _room?.dispose();
    await _roomEvents?.dispose();
    _connectionQualityTimer?.cancel();
    _localTimer?.cancel();
    _poiTimer?.cancel();
    return super.close();
  }
}
