import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/debate_models.dart';
import '../../domain/debate_result_view.dart';
import '../../domain/debate_room_role.dart';
import '../../domain/live_debate_data.dart';
import '../../domain/speech_detail.dart';
import '../utils/debate_timeline.dart';

part 'debate_state.dart';

/// The chat channel id used by the judge panel. Not a team id, so it can never
/// collide with one — a judge has no team.
const String kJudgesChatChannel = 'judges';

/// One step in the debate speaking flow.
class SpeechSlot {
  final DebateSide side;
  final int orderIndex; // index into that side's speaking order
  final bool isReply;
  const SpeechSlot({required this.side, required this.orderIndex, this.isReply = false});
}

/// A received team-chat message (rendered only for same-team viewers).
/// [seenBy] mirrors the backend's persisted `seen_by` — always
/// includes the sender. The unread dot is derived from it (my id ∉ seenBy),
/// not tracked as a separate counter. [id] is null only for the (rare) window
/// between a locally-sent message and its `POST /chat` response landing.
class TeamChatMessage {
  final int? id;
  final String teamId;
  final String senderId;
  final String senderName;
  final String message;
  final int ts;
  final List<String> seenBy;
  const TeamChatMessage({
    this.id,
    required this.teamId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.ts,
    this.seenBy = const [],
  });

  TeamChatMessage copyWith({int? id, List<String>? seenBy}) => TeamChatMessage(
        id: id ?? this.id,
        teamId: teamId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        ts: ts,
        seenBy: seenBy ?? this.seenBy,
      );
}

/// The shared surface every live-debate **widget** reads from.
/// One widget set, two controllers: [DebateCubit] (mock/test, peer-to-peer) and
/// `LiveDebateCubit` (backend, server-driven) both `extend DebateController`, so
/// `BlocBuilder<DebateController, DebateStates>` / `context.read<DebateController>`
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

  /// [notify]=false is the intentional-leave path: tears the
  /// connection down WITHOUT emitting [DebateDisconnectedState], so the
  /// room's pop-on-disconnect listener can't race the caller's own
  /// navigation. Unexpected disconnects keep the default and still notify.
  Future<void> disconnect({bool notify = true});
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

  /// This person's profile picture, or null when they have none (the cards then
  /// draw the coloured initial). Searched across both teams, the judge panel and
  /// the audience so any card can ask by id alone.
  String? avatarUrlForUser(String userId) {
    for (final side in DebateSide.values) {
      final d = teamFor(side).debaterById(userId);
      if (d != null) return d.avatarUrl;
    }
    for (final j in data.judges) {
      if (j.id == userId) return j.avatarUrl;
    }
    for (final a in data.audience) {
      if (a.id == userId) return a.avatarUrl;
    }
    return null;
  }

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

  /// How many fixed speaking slots to render per side (= speakers per
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

  /// Whether the local user currently holds the floor (is the main speaker).
  /// **Only the current speaker may accept/answer a POI**. Test/mock
  /// mode: true whenever a speech is live (the solo demo speaks as the local user).
  bool get iAmCurrentSpeaker => currentSlot != null;

  void sendPOIRequest();
  void acceptPOI(String askerSid);
  void refusePOI(String askerSid);
  void poiDone();

  /// The one entry point for the POI button: raises a hand, or takes down the
  /// one already up.
  void togglePOI() => isLocalAskingPOI ? lowerPOI() : sendPOIRequest();

  /// Take the local user's own raised hand down (tapped again, or expired).
  void lowerPOI() {}

  /// The local user raised a hand recently and must wait before raising
  /// another, whatever ended the last one.
  bool get isPoiCoolingDown => false;

  /// Seconds left on that wait, for the button's countdown.
  int get poiCooldownRemainingSeconds => 0;

  // ── News ────────────────────────────────────────────────────────────────────
  String get latestNews;
  void updateLatestNews(String message);
  void pushRandomNews(String Function(int n) build);

  // ── Lobby mode, moderation, chat ──────────────────────────────────────────────
  bool get isLobbyMode;
  List<TeamChatMessage> get chatMessages;
  Set<String> get presentIds;

  void setLobbyMode(bool enabled);

  /// Team-chat messages the local user hasn't seen yet (chat closed when they
  /// arrived). Drives the unread dot on the toolbar chat button. Default 0.
  int get unreadTeamChatCount => 0;

  /// Told by the chat dialog when it opens/closes so inbound messages only count
  /// as "unread" while the chat is closed. Default no-op.
  void setTeamChatOpen(bool open) {}

  /// The chair's next-stage request is currently in flight → the room shows a
  /// blocking loading overlay to prevent a double-tap skipping a speech. Default
  /// false (only the server-driven cubit sets it).
  bool get isAdvancingStage => false;

  // ── Intro phase + chair timer control ─────────────────────────────────
  /// The live session has started but no speech yet (chair welcome). Test mode:
  /// always false (the mock goes straight to a speech).
  bool get isIntro => false;

  /// During the intro, the user id / name shown in the main speaker card (the
  /// chair). Null/empty outside the intro or in test mode.
  String? get introHostId => null;
  String get introHostName => '';

  /// Chair: enter the live session from the lobby (intro). Test mode: no-op
  /// (toggling goes straight to the first speech as before).
  Future<void> startLive() async {}

  /// Chair: pause/resume the server-authoritative timer (the stop/resume button).
  /// Test mode: toggles the local clock.
  void toggleTimerPause() {}

  void muteAll();
  void forceMute(String targetSid);
  void forceCameraOff(String targetSid);
  void sendTeamChat({required String teamId, required String message});
  List<TeamChatMessage> chatFor(String viewerTeamId);

  /// The local user's own team id — used to scope team chat and its unread
  /// counter to the correct side. Checks both rosters explicitly rather than
  /// falling back to "opposition" for anyone not found on proposition, since
  /// that fallback used to also (wrongly) catch judges/viewers/trainers.
  String get myTeamId {
    final me = data.currentUserId;
    final prop = data.propositionTeam;
    if (prop.debaterById(me) != null) return prop.teamId;
    final opp = data.oppositionTeam;
    if (opp.debaterById(me) != null) return opp.teamId;
    // Not a debater on either roster (judge/viewer/trainer) — there is no
    // real team chat to scope to. Return a sentinel that can never match a
    // real team id instead of silently guessing "opposition".
    return '';
  }

  /// The one chat channel this user belongs to: the judge panel's if they are a
  /// judge, otherwise their team's. Nobody is ever in both, so a single channel
  /// per user keeps the unread count and the "chat is open" flag unambiguous.
  String get myChatChannelId => isJudgeOfDebate ? kJudgesChatChannel : myTeamId;

  /// Whether [myChatChannelId] is the judge panel's channel.
  bool get isJudgeChat => myChatChannelId == kJudgesChatChannel;

  // ── Moderation publish-lock ─────────────────────────────────────────
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

  // ── Camera lock (mirrors the mic publish-lock above/) ────────────
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

  // ── Share result / close room from the live room ─────────────────────

  /// The submitted result has already been shared to the room.
  bool get resultShared => false;

  /// Whether the reveal celebration has already played on this device. The
  /// result screen can be re-opened from the menu, and confetti every time
  /// would turn a moment into a nuisance.
  bool get resultCelebrated => false;
  void markResultCelebrated() {}

  /// The room has been closed by the chair.
  bool get isRoomClosed => false;

  /// Chair: reveal + push the result to every participant (confetti), and move
  /// the debate to its done/open-lobby state.
  Future<void> shareResult() async {}

  /// Chair: close the room — kick everyone back to the rooms list and lock the
  /// live-debate join.
  Future<void> closeRoom() async {}

  // ── Role → controls gating ───────────────────────────────────────────────
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

  /// A judge on this debate — chair or panel. Separate from [canManageResult]
  /// on purpose: the whole panel may *see* the ballot and the speech review;
  /// only the chair may submit or reveal it.
  bool get isJudgeOfDebate => canManageResult;

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

  /// Watching through a share link with no account. Guests see the room, the
  /// cards and the motion and nothing else — no toolbar, no menu, no sharing.
  bool get isGuest => false;

  /// The debate's public link, used by the share action. Null for guests, who
  /// must not be able to pass the link on.
  String? get shareUrl => null;

  /// Why the initial load failed, if it did. Lets the guest entry screen tell a
  /// closed share link (410) apart from a network problem.
  Failure? get loadFailure => null;

  // ── Result flow ─────────────────────────────────────────────────────────
  // Same widget set both modes: test stores the result locally; backend submits
  // over REST and reads it back from `live-state`.

  /// The stages to score in the chair's submit UI (6 or 8, reply included).
  List<ResultStageRef> get scoreableStages;

  /// Every speech of the debate with its timings, POI counts and transcript, in
  /// speaking order — what the judges' speech review reads. Empty in test mode.
  List<SpeechDetail> get speechDetails => const [];

  /// The render-ready result for the shared result widget. Null until a result
  /// exists (test: submitted; backend: `live-state.result` present or the debate
  /// is completed). [DebateResultView.revealed] tells the reveal status.
  DebateResultView? get resultView;

  /// The main room was closed with no result → the debate is cancelled.
  bool get isCancelled;

  /// The result phase is open (speeches finished) while the debate is still
  /// `live` — gate the result room on THIS, not on `debateFinished`/`completed`.
  /// Test/mock mode: opens when the local debate is finished.
  bool get resultPhaseOpen => debateFinished;

  /// A result has been stored (submitted) — drives enabling the chair's
  /// "share result" action in the LIVE room. Defaults to "a result view exists".
  bool get hasResult => resultView != null;

  /// Chair: submit scores. [scoresByStageOrder] is keyed by the 1-based stage
  /// order; [winningSide] picks the victor. **Returns whether the submit actually
  /// succeeded** so the UI never reports a false success.
  Future<bool> submitResult({
    required DebateSide winningSide,
    required Map<int, num> scoresByStageOrder,
    required String summaryNotes,
  });

  /// Chair: reveal the result in-room — plays the confetti reveal.
  Future<void> revealResult();

  /// Chair: close the main room — reveals an existing result (no confetti),
  /// otherwise cancels the debate.
  Future<void> closeMain();

  /// Submit a 1–5 debate rating with an optional free-text explanation. Sent
  /// once per explicit submit (never on every star change); the UI only enables
  /// this once the result is revealed.
  Future<void> sendDebateRating(int rating, {String? comment});

  // ── Muted-but-speaking banner ────────────────────────────────────────────────
  // The local user (main speaker or a judge) has their mic OFF while the voice
  // sensor catches them talking above a threshold → the room shows a top banner.
  // Default off; only the backend cubit runs the sensor.

  /// Whether the banner should be visible right now.
  bool get mutedSpeakingActive => false;

  /// User swiped the banner away — keep it hidden until the mic toggles or the
  /// monitored condition resets.
  void dismissMutedSpeakingBanner() {}

  // ── Backend integration seam ─────────────────────────────────────────────
  // Concrete defaults keep the test cubit unchanged; the backend cubit overrides.

  /// Whether [data] is usable. Backend mode is false until `live-state` loads.
  bool get isReady => true;

  /// One-time load (backend: profile id + live-state). Test mode is a no-op.
  Future<void> init() async {}

  /// Called by the debate room screen on entry (test: connect test creds + start
  /// as first speaker; backend: fetch the main-room token + connect + seed).
  Future<void> enterDebateRoom() async {}

  /// Backend: fetch a fresh room-scoped token and connect (token discipline,
  ///). Test mode is a no-op.
  Future<void> joinRoom(DebateRoomType type) async {}

  /// Backend pre-join gate from `live-state.rooms` (`joinable_for_me` +
  /// `role_if_joined`). Returns null in test mode → the lobby uses its local
  /// [DebateAccess] rules instead.
  ({bool joinable, DebateRoomRole? role})? backendRoomGate(DebateRoomType type) => null;
}
