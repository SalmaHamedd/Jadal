import 'dart:convert';

/// Codec for the **backend** live-debate data-channel messages, which use an
/// `{"event": …}` envelope (distinct from the test-mode [DebateSocketProtocol],
/// which uses `{"type": …}`). The backend publishes most of these; the client
/// publishes POI flashes and — per §7 — the chair publishes the timer
/// (`time_update`/`time_control`), which the backend passively persists.
enum LiveEventType {
  // Backend-published (main room).
  stageChanged('stage_changed'),
  debateModeStarted('debate_mode_started'),
  returnedToLobby('returned_to_lobby'),
  participantAttended('participant_attended'),
  chairElected('chair_elected'),
  // FE-3 (B1): speeches finished → the result phase opens while status is STILL
  // `live`. Replaces the legacy `debate_completed` for opening the result room.
  speechesCompleted('speeches_completed'),
  debateCompleted('debate_completed'),
  resultRevealed('result_revealed'),
  // Chair force-closed the main room (backend close-room, §FE-7). Sent right
  // before the LiveKit room is deleted so every client can leave cleanly.
  roomClosed('room_closed'),
  // Client-published peer flashes.
  poiRaised('poi_raised'),
  poiAnswered('poi_answered'),
  // V11 §0: server-authoritative timer broadcast (pause/resume/no-judge). This
  // REPLACES the chair-peer `time_update` as the source of truth.
  timerUpdate('timer_update'),
  // Legacy chair-published timer (§7) — retired as the source of truth, kept so
  // an in-flight message from an old client still decodes harmlessly.
  timeUpdate('time_update'),
  timeControl('time_control'),
  teamChat('team_chat'),
  // Chair-published open-lobby PAUSE overlay: a break that freezes the current
  // speaker + timer (so it resumes where it stopped), without touching the
  // backend stage. Peer-to-peer, like the timer (§open-lobby).
  lobbyOverlay('lobby_overlay'),
  // Chair moderation fallback over the data channel (peer self-mutes). The docs
  // prefer LiveKit `roomAdmin`, which the Flutter client SDK doesn't expose, so
  // the chair signals the target to mute/disable its own track.
  forceMute('force_mute'),
  forceCameraOff('force_camera_off'),
  // Chair publish-lock: the room-wide / per-user mic + camera lock state. Unlike
  // the fire-once force_* nudges above, this is the durable lock that prevents a
  // non-exempt user from re-opening their mic/camera until released (§FE-4).
  publishLock('publish_lock');

  final String wire;
  const LiveEventType(this.wire);

  static LiveEventType? fromWire(String? raw) {
    for (final t in LiveEventType.values) {
      if (t.wire == raw) return t;
    }
    return null;
  }
}

/// A decoded backend data-channel message.
class LiveEvent {
  final LiveEventType type;
  final Map<String, dynamic> data;
  const LiveEvent(this.type, this.data);

  // stage_changed
  int? get currentStage => (data['current_stage'] as num?)?.toInt();
  int? get speakerUserId => (data['speaker_user_id'] as num?)?.toInt();
  int? get durationSeconds => (data['duration_seconds'] as num?)?.toInt();
  String? get serverStartedAt => data['server_started_at'] as String?;

  // participant_attended / chair_elected
  int? get userId => (data['user_id'] as num?)?.toInt();
  int? get chairUserId => (data['chair_user_id'] as num?)?.toInt();

  // poi_raised / poi_answered
  int? get stagePhaseId => (data['stage_phase_id'] as num?)?.toInt();
  int? get byUserId => (data['by_user_id'] as num?)?.toInt();

  // time_update / time_control (chair-published, legacy)
  int get elapsedSeconds => (data['elapsedSeconds'] as num?)?.toInt() ?? 0;
  bool get isPaused => data['isPaused'] == true;
  String? get timestamp => data['timestamp'] as String?;
  String? get action => data['action'] as String?;

  // timer_update (server-authoritative, V11 §0)
  String? get currentStageStartedAt => data['current_stage_started_at'] as String?;
  String? get serverNow => data['server_now'] as String?;
  bool get timerIsPaused => data['timer_is_paused'] == true;
  int get timerPausedElapsedSeconds =>
      (data['timer_paused_elapsed_seconds'] as num?)?.toInt() ?? 0;
  String? get pauseReason => data['reason'] as String?;

  // poi_answered: whether the POI was accepted (asker may speak) or refused.
  bool get poiAccepted => data['accepted'] == true;

  // lobby_overlay
  bool get lobbyOverlayEnabled => data['enabled'] == true;

  // team_chat
  String? get teamId => data['teamId'] as String?;
  String? get senderId => data['senderId'] as String?;
  String? get senderName => data['senderName'] as String?;
  String? get message => data['message'] as String?;
  int get ts => (data['ts'] as num?)?.toInt() ?? 0;

  // force_mute / force_camera_off
  int? get targetUserId => (data['target_user_id'] as num?)?.toInt();

  // publish_lock — durable mic/camera lock state broadcast by the chair.
  bool get muteAllMic => data['mute_all_mic'] == true;
  bool get cameraAllOff => data['camera_all_off'] == true;
  List<String> get micLockedIds =>
      (data['mic_locked_ids'] as List?)?.map((e) => '$e').toList() ?? const [];
  List<String> get cameraLockedIds =>
      (data['camera_locked_ids'] as List?)?.map((e) => '$e').toList() ?? const [];
}

abstract class LiveDebateSocket {
  static List<int> _encode(Map<String, dynamic> map) => utf8.encode(jsonEncode(map));

  // FE-4: the phase id is OPTIONAL on the peer flash — it's often null and must
  // never block the broadcast (only the REST persistence needs it). `by_user_id`
  // is what every device keys the POI badge off.
  static List<int> poiRaised({int? stagePhaseId, required int byUserId}) =>
      _encode({
        'event': LiveEventType.poiRaised.wire,
        'stage_phase_id': stagePhaseId,
        'by_user_id': byUserId,
      });

  /// [accepted] = the speaker accepted the asker (they may speak) vs refused.
  /// Carries the ASKER's id in `by_user_id` so every device clears that asker's
  /// badge and the asker learns the outcome (B1/B2).
  static List<int> poiAnswered({
    int? stagePhaseId,
    required int byUserId,
    bool accepted = false,
  }) =>
      _encode({
        'event': LiveEventType.poiAnswered.wire,
        'stage_phase_id': stagePhaseId,
        'by_user_id': byUserId,
        'accepted': accepted,
      });

  static List<int> timeUpdate({
    required int elapsedSeconds,
    required bool isPaused,
    required DateTime timestamp,
  }) =>
      _encode({
        'event': LiveEventType.timeUpdate.wire,
        'elapsedSeconds': elapsedSeconds,
        'isPaused': isPaused,
        'timestamp': timestamp.toIso8601String(),
      });

  static List<int> timeControl({required bool pause}) => _encode({
        'event': LiveEventType.timeControl.wire,
        'action': pause ? 'pause' : 'resume',
      });

  static List<int> lobbyOverlay({required bool enabled}) => _encode({
        'event': LiveEventType.lobbyOverlay.wire,
        'enabled': enabled,
      });

  static List<int> forceMute(int targetUserId) =>
      _encode({'event': LiveEventType.forceMute.wire, 'target_user_id': targetUserId});

  static List<int> forceCameraOff(int targetUserId) =>
      _encode({'event': LiveEventType.forceCameraOff.wire, 'target_user_id': targetUserId});

  /// The chair's durable publish-lock state (mic + camera), broadcast on every
  /// change so late joiners and everyone else converge on the same lock (§FE-4).
  static List<int> publishLock({
    required bool muteAllMic,
    required List<String> micLockedIds,
    required bool cameraAllOff,
    required List<String> cameraLockedIds,
  }) =>
      _encode({
        'event': LiveEventType.publishLock.wire,
        'mute_all_mic': muteAllMic,
        'mic_locked_ids': micLockedIds,
        'camera_all_off': cameraAllOff,
        'camera_locked_ids': cameraLockedIds,
      });

  static List<int> teamChat({
    required String teamId,
    required String senderId,
    required String senderName,
    required String message,
    required int ts,
  }) =>
      _encode({
        'event': LiveEventType.teamChat.wire,
        'teamId': teamId,
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'ts': ts,
      });

  /// Parses raw bytes; returns null for unknown/invalid payloads so callers can
  /// ignore them safely.
  static LiveEvent? decode(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) return null;
      final type = LiveEventType.fromWire(decoded['event'] as String?);
      if (type == null) return null;
      return LiveEvent(type, decoded);
    } catch (_) {
      return null;
    }
  }
}
