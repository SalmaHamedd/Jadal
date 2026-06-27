import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../data/models/debate_models.dart';
import '../../domain/debate_result_view.dart';
import '../../domain/debate_room_role.dart';
import '../../domain/live_debate_data.dart';
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

/// The shared surface every live-debate **widget** reads from (§2).
///
/// One widget set, two controllers: [DebateCubit] (mock/test, peer-to-peer) and
/// `LiveDebateCubit` (backend, server-driven) both `extend DebateController`, so
/// `BlocBuilder<DebateController, DebateStates>` / `context.read<DebateController>()`
/// render either mode identically. The **only** intended difference is role-gating —
/// the permission getters below are all-permissive in test mode and derived from the
/// token `role_in_room` + live-state in backend mode.
abstract class DebateController extends Cubit<DebateStates> {
  DebateController(super.initialState);

  // ── Data + timeline ────────────────────────────────────────────────────────
  LiveDebateData get data;
  DebateTimeline get timeline;

  /// Whether this client is the timer/flow authority (test: always; backend: chair).
  bool get isAuthority;

  // ── Connection / media ──────────────────────────────────────────────────────
  LocalParticipant? get localParticipant;
  List<RemoteParticipant> get participants;
  ConnectionQuality get connectionQuality;
  LocalVideoTrack? get localVideoTrack;
  bool get isMicEnabled;
  bool get isCameraEnabled;
  bool get isLocalSpeaking;

  /// Local mic audio level (0..1) for the volume meter. Defaults to 0; the
  /// concrete cubits read it live from the LiveKit participant.
  double get localAudioLevel => 0;

  bool remoteHasAudio(String sid);
  bool remoteHasVideo(String sid);
  bool remoteSpeaking(String sid);
  VideoTrack? remoteVideoTrack(RemoteParticipant p);
  String firstName(String? full);

  Future<void> connectToRoom({required String url, required String token});
  Future<void> disconnect();
  void toggleMic();
  void toggleCamera();

  // ── Presence (who is *actually* in the room) ────────────────────────────────
  // The roster (live-state speakers/judges) is NOT presence — a P2 slot can be
  // assigned to a user who never connected. Cards must render real presence and
  // fall back ("hasn't joined yet") otherwise. The defaults below keep test/mock
  // mode showing the full roster (a solo demo); the backend cubit overrides them
  // from the live LiveKit participant list.

  /// Whether the user with [userId] is connected to this room right now.
  bool isUserPresent(String userId) => true;

  /// The connected remote participant for [userId] (backend mode), else null.
  RemoteParticipant? remoteParticipantById(String userId) => null;

  /// Whether [userId] is the local user. Both data sources expose the local id
  /// as [LiveDebateData.currentUserId].
  bool isLocalUserId(String userId) => userId == data.currentUserId;

  /// Whether this user's camera should render (local toggle or a subscribed
  /// remote track). Falls back to the avatar when false.
  bool showVideoForUser(String userId) {
    if (isLocalUserId(userId)) return isCameraEnabled && localVideoTrack != null;
    final p = remoteParticipantById(userId);
    return p != null && remoteHasVideo(p.sid);
  }

  /// The camera track to render for [userId] (local or a present remote), or null.
  VideoTrack? videoTrackForUser(String userId) {
    if (isLocalUserId(userId)) return localVideoTrack;
    final p = remoteParticipantById(userId);
    return p == null ? null : remoteVideoTrack(p);
  }

  bool micOnForUser(String userId) {
    if (isLocalUserId(userId)) return isMicEnabled;
    final p = remoteParticipantById(userId);
    return p != null && remoteHasAudio(p.sid);
  }

  bool speakingForUser(String userId) {
    if (isLocalUserId(userId)) return isLocalSpeaking;
    final p = remoteParticipantById(userId);
    return p != null && remoteSpeaking(p.sid);
  }

  // ── Timer + tier ────────────────────────────────────────────────────────────
  int get elapsedSeconds;
  bool get isPaused;
  DebateTier get currentTier;
  bool get poiOpen;

  void startTimer();
  void pauseTimer();
  void resumeTimer();
  void resetTimer();

  // ── Debate flow ──────────────────────────────────────────────────────────────
  SpeechSlot? get currentSlot;
  DebateSide get currentSpeakerSide;
  DebateSide get localSide;
  bool get debateStarted;
  bool get debateFinished;
  bool get isLastStep;

  void advanceDebate();
  void startAsFirstSpeaker();
  void markDebateDone();

  // ── Speaker resolution ────────────────────────────────────────────────────────
  TeamInfo teamFor(DebateSide side);
  SpeakerOrder orderFor(DebateSide side);
  SpeakerOrder get propOrder;
  SpeakerOrder get oppOrder;
  Debater debaterAt(DebateSide side, int orderIndex);

  /// FE-7: how many fixed speaking slots to render per side (= speakers per
  /// side). Both team columns render this many cards so they stay equal height;
  /// a side with fewer speakers leaves its bottom slot(s) empty. Default: the
  /// larger side's roster (test mode is symmetric, so this is unchanged there).
  int get speakersPerSide {
    final p = teamFor(DebateSide.proposition).debaters.length;
    final o = teamFor(DebateSide.opposition).debaters.length;
    return p >= o ? p : o;
  }
  String roleLabel(DebateSide side, int orderIndex);
  String roleLabelForSlot(SpeechSlot slot);
  bool isCurrentSpeaker(DebateSide side, int orderIndex);

  void setSpeakerOrder({
    required String teamId,
    required List<String> orderedSpeakerIds,
    String? replySpeakerId,
  });

  // ── POI ───────────────────────────────────────────────────────────────────────
  bool get isLocalAskingPOI;
  bool get localPoiAccepted;
  Set<String> get askingPoiSids;
  bool isAskingPOIByDebater(String debaterId);
  bool isAskingPOIBySid(String sid);

  void sendPOIRequest();
  void acceptPOI(String askerSid);
  void refusePOI(String askerSid);
  void poiDone();

  // ── News ────────────────────────────────────────────────────────────────────
  String get latestNews;
  void updateLatestNews(String message);
  void pushRandomNews(String Function(int n) build);

  // ── Lobby mode, moderation, chat ──────────────────────────────────────────────
  bool get isLobbyMode;
  List<TeamChatMessage> get chatMessages;
  Set<String> get presentIds;

  void setLobbyMode(bool enabled);
  void muteAll();
  void forceMute(String targetSid);
  void forceCameraOff(String targetSid);
  void sendTeamChat({required String teamId, required String message});
  List<TeamChatMessage> chatFor(String viewerTeamId);

  // ── Moderation publish-lock (§U4b) ─────────────────────────────────────────
  // "Mute all = prevent publishing" + per-user lock. Concrete no-op defaults so
  // the backend cubit compiles unchanged (those endpoints don't exist yet, so
  // it inherits the stubs); the test cubit implements them over the data channel.

  /// Room-wide publish lock is active (everyone but judges + the main speaker
  /// cannot open their mic). The chair button then offers "unmute all".
  bool get muteAllActive => false;

  /// User ids individually blocked from publishing.
  Set<String> get publishLockedIds => const {};

  /// Whether the local user may open their mic right now (not publish-locked).
  bool get canPublishNow => true;

  /// Chair: toggle the room-wide publish lock.
  void toggleMuteAll() {}

  /// Chair: toggle an individual user's publish lock.
  void toggleUserPublishLock(String userId) {}

  // ── Camera lock (mirrors the mic publish-lock above, §FE-4/FE-6) ────────────
  // Same model for the camera: a room-wide "camera off (all)" and a per-user
  // lock so a user the chair turned off can't re-open their camera. Judges + the
  // current main speaker are always exempt. No-op defaults keep both cubits
  // compiling; the concrete cubits override them.

  /// Room-wide camera lock is active (everyone but judges + the main speaker
  /// cannot open their camera). The chair button then offers "allow camera all".
  bool get cameraAllOff => false;

  /// User ids individually blocked from opening their camera.
  Set<String> get cameraLockedIds => const {};

  /// Whether the local user may open their camera right now (not camera-locked).
  bool get canEnableCameraNow => true;

  /// Chair: toggle the room-wide camera lock.
  void toggleCameraAll() {}

  /// Chair: toggle an individual user's camera lock.
  void toggleUserCameraLock(String userId) {}

  // ── Share result / close room from the live room (§U4b) ─────────────────────

  /// The submitted result has already been shared to the room.
  bool get resultShared => false;

  /// The room has been closed by the chair.
  bool get isRoomClosed => false;

  /// Chair: reveal + push the result to every participant (confetti), and move
  /// the debate to its done/open-lobby state.
  Future<void> shareResult() async {}

  /// Chair: close the room — kick everyone back to the rooms list and lock the
  /// live-debate join.
  Future<void> closeRoom() async {}

  // ── Role → controls gating (§8) ───────────────────────────────────────────────
  // Test mode returns all-permissive (shows every control); backend mode derives
  // these from the token `role_in_room` + live-state. Widgets HIDE controls a role
  // can never use and DISABLE ones momentarily unavailable.
  /// Chair only: mute / force-camera-off others (LiveKit `roomAdmin`).
  bool get canModerateOthers;

  /// Chair only: start / next-stage / rollback / open-lobby toggle.
  bool get canControlStage;

  /// Chair only: pause / resume the speaker's timer.
  bool get canControlTimer;

  /// Chair only: submit / reveal / close-main (result actions).
  bool get canManageResult;

  /// May toggle mic/camera right now (role- and lobby-aware: everyone in the open
  /// lobby; participants/judges in a live stage; spectators never in a live stage).
  bool get canUseMedia;

  /// Role may ask a POI at all → whether to **show** the POI button (a speaking
  /// debater). Whether it's currently pressable is [poiEnabledNow].
  bool get canAskPoi;

  /// POI is allowed **right now**: the open window is active AND the current
  /// speaker is on the opposing side (test mode: always true so it's exercisable).
  bool get poiEnabledNow;

  /// Role may open team chat now (a debater who is not the current main speaker).
  bool get canOpenChat;

  /// Viewer / trainer / a team member who is not a speaking participant.
  bool get isSpectator;

  // ── Result flow (§10) ─────────────────────────────────────────────────────────
  // Same widget set both modes: test stores the result locally; backend submits
  // over REST and reads it back from `live-state`.

  /// The stages to score in the chair's submit UI (6 or 8, reply included).
  List<ResultStageRef> get scoreableStages;

  /// The render-ready result for the shared result widget. Null until a result
  /// exists (test: submitted; backend: `live-state.result` present or the debate
  /// is completed). [DebateResultView.revealed] tells the reveal status.
  DebateResultView? get resultView;

  /// The main room was closed with no result → the debate is cancelled (§10).
  bool get isCancelled;

  /// FE-3: the result phase is open (speeches finished) while the debate is still
  /// `live` — gate the result room on THIS, not on `debateFinished`/`completed`.
  /// Test/mock mode: opens when the local debate is finished.
  bool get resultPhaseOpen => debateFinished;

  /// FE-6: a result has been stored (submitted) — drives enabling the chair's
  /// "share result" action in the LIVE room. Defaults to "a result view exists".
  bool get hasResult => resultView != null;

  /// Chair: submit scores. [scoresByStageOrder] is keyed by the 1-based stage
  /// order; [winningSide] picks the victor. **Returns whether the submit actually
  /// succeeded** (FE-1) so the UI never reports a false success.
  Future<bool> submitResult({
    required DebateSide winningSide,
    required Map<int, num> scoresByStageOrder,
    required String summaryNotes,
  });

  /// Chair: reveal the result in-room — plays the confetti reveal (§10).
  Future<void> revealResult();

  /// Chair: close the main room — reveals an existing result (no confetti),
  /// otherwise cancels the debate (§10).
  Future<void> closeMain();

  /// Submit a 1–5 debate rating. The UI only enables this once the result is
  /// revealed and the debate is completed (§10).
  Future<void> sendDebateRating(int rating);

  // ── Backend integration seam (§7) ─────────────────────────────────────────────
  // Concrete defaults keep the test cubit unchanged; the backend cubit overrides.

  /// Whether [data] is usable. Backend mode is false until `live-state` loads.
  bool get isReady => true;

  /// One-time load (backend: profile id + live-state). Test mode is a no-op.
  Future<void> init() async {}

  /// Called by the debate room screen on entry (test: connect test creds + start
  /// as first speaker; backend: fetch the main-room token + connect + seed).
  Future<void> enterDebateRoom() async {}

  /// Backend: fetch a fresh room-scoped token and connect (token discipline,
  /// §7). Test mode is a no-op.
  Future<void> joinRoom(DebateRoomType type) async {}

  /// Backend pre-join gate from `live-state.rooms` (`joinable_for_me` +
  /// `role_if_joined`). Returns null in test mode → the lobby uses its local
  /// [DebateAccess] rules instead.
  ({bool joinable, DebateRoomRole? role})? backendRoomGate(DebateRoomType type) => null;
}
