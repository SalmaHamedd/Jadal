import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../data/datasources/mock_live_debate_data.dart';
import '../../data/debate_socket_protocol.dart';
import '../../data/models/debate_models.dart';
import '../utils/debate_timeline.dart';

part 'debate_state.dart';

/// One step in the debate speaking flow.
class SpeechSlot {
  final DebateSide side;
  final int orderIndex; // index into that side's speaking order
  final bool isReply;
  const SpeechSlot({required this.side, required this.orderIndex, this.isReply = false});
}

/// A received team-chat message (rendered only for same-team viewers).
class TeamChatMessage {
  final String teamId;
  final String senderId;
  final String senderName;
  final String message;
  final int ts;
  const TeamChatMessage({
    required this.teamId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.ts,
  });
}

/// Rebuilt live-debate cubit (ported from the legacy `CallCubit`, §1/§6/§8).
///
/// Owns the LiveKit room, the timer + its [DebateFormat]-driven timeline, POI
/// state, the speaking flow, speaker order, lobby mode and team chat. All
/// data-channel traffic goes through [DebateSocketProtocol] on
/// [DebateSocketProtocol.topic].
class DebateCubit extends Cubit<DebateStates> {
  DebateCubit({required this.data}) : super(DebateInitialState()) {
    timeline = DebateTimeline(data.format);
    _buildSequence();
    _seedOrders();
  }

  final MockLiveDebateData data;
  late final DebateTimeline timeline;

  // ── LiveKit ────────────────────────────────────────────────────────────────
  Room? _room;
  EventsListener<RoomEvent>? _roomEvents;
  ConnectionQuality connectionQuality = ConnectionQuality.unknown;
  LocalParticipant? localParticipant;

  List<RemoteParticipant> participants = [];
  final Map<String, bool> _remoteHasAudio = {};
  final Map<String, bool> _remoteHasVideo = {};
  final Map<String, bool> _remoteSpeaking = {};

  LocalVideoTrack? localVideoTrack;
  LocalAudioTrack? localAudioTrack;
  bool isLocalSpeaking = false;
  bool isMicEnabled = false;
  bool isCameraEnabled = false;

  // ── Timer ──────────────────────────────────────────────────────────────────
  int elapsedSeconds = 0;
  bool isPaused = true;
  Timer? _localTimer;
  Timer? _connectionQualityTimer;

  /// In test mode the local user is the active speaker → authority.
  bool get isAuthority => true; // TODO(role-gating): judge/speaker drives this.

  // ── Debate flow ──────────────────────────────────────────────────────────
  final List<SpeechSlot> _sequence = [];
  int _currentStep = -1; // -1 = not started
  bool debateStarted = false;
  bool debateFinished = false;

  /// In test mode the local user represents the proposition's first speaker.
  DebateSide get localSide => DebateSide.proposition;

  SpeechSlot? get currentSlot =>
      (_currentStep >= 0 && _currentStep < _sequence.length) ? _sequence[_currentStep] : null;

  DebateSide get currentSpeakerSide => currentSlot?.side ?? DebateSide.proposition;

  // ── POI ──────────────────────────────────────────────────────────────────
  final Set<String> _askingPoiSids = {};
  bool isLocalAskingPOI = false;
  bool localPoiAccepted = false; // asker may open mic (shows the mic dialog)
  Timer? _poiTimer;

  // ── News ───────────────────────────────────────────────────────────────────
  String latestNews = '';
  int _newsCounter = 1;

  // ── Speaker order ────────────────────────────────────────────────────────
  late SpeakerOrder propOrder;
  late SpeakerOrder oppOrder;

  // ── Lobby mode + chat ──────────────────────────────────────────────────────
  bool isLobbyMode = false;
  final List<TeamChatMessage> _chat = [];
  List<TeamChatMessage> get chatMessages => List.unmodifiable(_chat);

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

  Future<void> connectToRoom({required String url, required String token}) async {
    emit(DebateConnectingState());
    try {
      _room = Room(
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );
      _roomEvents = _room!.createListener();
      _registerRoomListeners();
      await _room!.connect(url, token);
      localParticipant = _room!.localParticipant;
      await localParticipant?.setCameraEnabled(false);
      await localParticipant?.setMicrophoneEnabled(false);
      localVideoTrack = _localVideoTrack();
      localAudioTrack = _localAudioTrack();
      _startConnectionQualityTimer();
      emit(DebateConnectedState());
      emit(LocalTrackUpdatedState());
    } catch (e) {
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

  bool _participantSpeaking(Participant? p) => (p?.audioLevel ?? 0) > 3.0;

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
      ..on<ParticipantConnectedEvent>((_) => _refreshParticipants())
      ..on<ParticipantDisconnectedEvent>((event) {
        _askingPoiSids.remove(event.participant.sid);
        _refreshParticipants();
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
    isLocalSpeaking = _participantSpeaking(localParticipant);
    final tmp = <RemoteParticipant>[];
    for (final p in _room!.remoteParticipants.values) {
      tmp.add(p);
      _remoteHasAudio[p.sid] = _remoteMicOn(p);
      _remoteHasVideo[p.sid] = _remoteCameraOn(p);
      p.createListener().on<SpeakingChangedEvent>((e) {
        _remoteSpeaking[p.sid] = e.speaking;
        if (!isClosed) emit(RemoteTrackReceivedState());
      });
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

  void toggleMic() {
    isMicEnabled = !isMicEnabled;
    _room?.localParticipant?.setMicrophoneEnabled(isMicEnabled);
    localAudioTrack = _localAudioTrack();
    emit(MicToggledState());
    emit(LocalTrackUpdatedState());
  }

  void toggleCamera() {
    isCameraEnabled = !isCameraEnabled;
    _room?.localParticipant?.setCameraEnabled(isCameraEnabled);
    localVideoTrack = _localVideoTrack();
    emit(CameraToggledState());
    emit(LocalTrackUpdatedState());
  }

  bool remoteHasAudio(String sid) => _remoteHasAudio[sid] ?? false;
  bool remoteHasVideo(String sid) => _remoteHasVideo[sid] ?? false;
  bool remoteSpeaking(String sid) => _remoteSpeaking[sid] ?? false;

  VideoTrack? remoteVideoTrack(RemoteParticipant p) =>
      p.videoTrackPublications.firstOrNull?.track;

  String firstName(String? full) {
    final name = (full ?? '').trim();
    if (name.isEmpty) return 'User';
    return name.split(' ').first;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Timer + timeline (§8.3 B)
  // ──────────────────────────────────────────────────────────────────────────

  void startTimer() {
    isPaused = false;
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isPaused || isClosed) return;
      elapsedSeconds++;
      final event = timeline.eventAt(elapsedSeconds);
      if (event != null) emit(DebateTimelineEventState(event));
      emit(TimerTickedState());
      if (isAuthority) _broadcastTime();
    });
  }

  void pauseTimer() {
    isPaused = true;
    if (isAuthority) _publish(DebateSocketProtocol.timeControl(pause: true));
    emit(TimerTickedState());
  }

  void resumeTimer() {
    if (isAuthority) _publish(DebateSocketProtocol.timeControl(pause: false));
    startTimer();
  }

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

  DebateTier get currentTier => timeline.tierAt(elapsedSeconds);
  bool get poiOpen => timeline.poiOpenAt(elapsedSeconds) && currentSlot != null;

  // ──────────────────────────────────────────────────────────────────────────
  // Debate flow (next-state button, §8.6)
  // ──────────────────────────────────────────────────────────────────────────

  /// Whether the next press marks the debate done (after the last speech).
  bool get isLastStep => _currentStep >= _sequence.length - 1;

  /// Start → next speaker → mark done. In test mode the local user remains the
  /// active speaker; only the role slot advances (§9).
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
  void startAsFirstSpeaker() {
    if (!debateStarted) advanceDebate();
  }

  /// Marks the debate done — unlocks the Result room and is the chair's
  /// "finish" action (§8.6).
  // TODO(role-gating): restrict to the chair judge.
  void markDebateDone() {
    debateFinished = true;
    isPaused = true;
    _localTimer?.cancel();
    emit(DebateFinishedState());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Speaker resolution helpers (used by the speakers section)
  // ──────────────────────────────────────────────────────────────────────────

  TeamInfo teamFor(DebateSide side) =>
      side == DebateSide.proposition ? data.propositionTeam : data.oppositionTeam;

  SpeakerOrder orderFor(DebateSide side) =>
      side == DebateSide.proposition ? propOrder : oppOrder;

  /// The debater speaking in [side]'s slot [orderIndex], following the order if
  /// set, else the roster order.
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

  String roleLabelForSlot(SpeechSlot slot) {
    if (slot.isReply) return slot.side.replySuffix;
    return roleLabel(slot.side, slot.orderIndex);
  }

  /// Whether [side]/[orderIndex] is the speaker currently holding the floor.
  bool isCurrentSpeaker(DebateSide side, int orderIndex) {
    final slot = currentSlot;
    if (slot == null) return false;
    return slot.side == side && slot.orderIndex == orderIndex;
  }

  bool isAskingPOIByDebater(String debaterId) {
    // In test mode the local user maps to the active proposition speaker.
    if (isLocalAskingPOI && debaterId == debaterAt(localSide, 0).id) return true;
    return false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // POI (§8.4)
  // ──────────────────────────────────────────────────────────────────────────

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
  void refusePOI(String askerSid) {
    _askingPoiSids.remove(askerSid);
    if (askerSid == localParticipant?.sid) isLocalAskingPOI = false;
    emit(POIChangedState());
  }

  /// Asker finished their POI → return to silence.
  void poiDone() {
    localPoiAccepted = false;
    _publish(DebateSocketProtocol.poiDone(localParticipant?.sid ?? 'local'));
    if (isMicEnabled) toggleMic();
    emit(POIChangedState());
  }

  bool isAskingPOIBySid(String sid) => _askingPoiSids.contains(sid);
  Set<String> get askingPoiSids => Set.unmodifiable(_askingPoiSids);

  /// Identities currently present, used for leader/chair resolution (§8.1).
  /// In solo test mode this is just the mock [MockLiveDebateData.currentUserId].
  // TODO(role-gating): map real LiveKit identities to mock ids for presence.
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

  void updateLatestNews(String message) {
    latestNews = message;
    _publish(DebateSocketProtocol.newsUpdate(message));
    emit(NewsUpdatedState());
  }

  /// Test action: pushes a random news message (§8.6).
  void pushRandomNews(String Function(int n) build) =>
      updateLatestNews(build(_newsCounter++));

  // ──────────────────────────────────────────────────────────────────────────
  // Speaker order (§8.1)
  // ──────────────────────────────────────────────────────────────────────────

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

  // TODO(role-gating): judge-only.
  void setLobbyMode(bool enabled) {
    isLobbyMode = enabled;
    _publish(DebateSocketProtocol.lobbyMode(enabled: enabled));
    emit(LobbyModeChangedState());
  }

  // TODO(role-gating): judge-only.
  void muteAll() {
    for (final p in participants) {
      _publish(DebateSocketProtocol.forceMute(p.sid));
    }
    emit(POIChangedState());
  }

  // TODO(role-gating): judge-only.
  void forceMute(String targetSid) => _publish(DebateSocketProtocol.forceMute(targetSid));

  // TODO(role-gating): judge-only.
  void forceCameraOff(String targetSid) =>
      _publish(DebateSocketProtocol.forceCameraOff(targetSid));

  /// Sends a team-chat message visible only to same-team participants.
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
  List<TeamChatMessage> chatFor(String viewerTeamId) =>
      _chat.where((m) => m.teamId == viewerTeamId).toList();

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

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
