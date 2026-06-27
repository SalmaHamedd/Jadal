import 'dart:convert';

/// Centralized schema for the LiveKit data-channel messages exchanged on topic
/// [topic] (§6). All encode/decode lives here so message types are not
/// stringly-typed and scattered around the cubit.
///
/// Fixes the legacy bug where the sender published `news_update` but the
/// receiver matched `new_update`: the single source of truth is
/// [DebateEventType.newsUpdate.wire] == 'news_update'.

enum DebateEventType {
  poiRequest('poi_request'),
  poiAccepted('poi_accepted'),
  poiDone('poi_done'),
  newsUpdate('news_update'),
  timeUpdate('time_update'),
  timeControl('time_control'),
  speakerState('speaker_state'),
  speakerOrderUpdate('speaker_order_update'),
  forceMute('force_mute'),
  forceCameraOff('force_camera_off'),
  teamChat('team_chat'),
  lobbyMode('lobby_mode'),
  publishLock('publish_lock'),
  shareResult('share_result'),
  closeRoom('close_room');

  final String wire;
  const DebateEventType(this.wire);

  static DebateEventType? fromWire(String? raw) {
    for (final t in DebateEventType.values) {
      if (t.wire == raw) return t;
    }
    return null;
  }
}

/// A decoded data-channel message: its [type] plus the raw payload [data].
/// Typed getters cover the fields used across the feature.
class DebateEvent {
  final DebateEventType type;
  final Map<String, dynamic> data;

  const DebateEvent(this.type, this.data);

  String? get sid => data['sid'] as String?;
  String? get targetSid => data['targetSid'] as String?;
  String? get message => data['message'] as String?;
  String? get action => data['action'] as String?;
  bool get enabled => data['enabled'] == true;

  // speaker_state
  String? get speakerSid => data['speakerSid'] as String?;
  String? get role => data['role'] as String?;
  String? get side => data['side'] as String?;
  int get index => (data['index'] as num?)?.toInt() ?? 0;

  // speaker_order_update
  String? get teamId => data['teamId'] as String?;
  List<String> get orderedSpeakerIds =>
      (data['orderedSpeakerIds'] as List?)?.map((e) => '$e').toList() ?? const [];
  String? get replySpeakerId => data['replySpeakerId'] as String?;

  // team_chat
  String? get senderId => data['senderId'] as String?;
  String? get senderName => data['senderName'] as String?;
  int get ts => (data['ts'] as num?)?.toInt() ?? 0;

  // time_update
  int get elapsedSeconds => (data['elapsedSeconds'] as num?)?.toInt() ?? 0;
  bool get isPaused => data['isPaused'] == true;
  String? get timestamp => data['timestamp'] as String?;

  // publish_lock (mic + camera)
  bool get muteAll => data['muteAll'] == true;
  List<String> get lockedIds =>
      (data['lockedIds'] as List?)?.map((e) => '$e').toList() ?? const [];
  bool get cameraAllOff => data['cameraAllOff'] == true;
  List<String> get cameraLockedIds =>
      (data['cameraLockedIds'] as List?)?.map((e) => '$e').toList() ?? const [];
}

/// Builds and parses the data-channel payloads.
abstract class DebateSocketProtocol {
  static const String topic = 'debate-events';

  static List<int> _encode(Map<String, dynamic> map) => utf8.encode(jsonEncode(map));

  // ── Encoders ───────────────────────────────────────────────────────────────

  static List<int> poiRequest(String sid) =>
      _encode({'type': DebateEventType.poiRequest.wire, 'sid': sid});

  static List<int> poiAccepted(String targetSid) =>
      _encode({'type': DebateEventType.poiAccepted.wire, 'targetSid': targetSid});

  static List<int> poiDone(String sid) =>
      _encode({'type': DebateEventType.poiDone.wire, 'sid': sid});

  static List<int> newsUpdate(String message) =>
      _encode({'type': DebateEventType.newsUpdate.wire, 'message': message});

  static List<int> timeUpdate({
    required int elapsedSeconds,
    required bool isPaused,
    required DateTime timestamp,
  }) =>
      _encode({
        'type': DebateEventType.timeUpdate.wire,
        'elapsedSeconds': elapsedSeconds,
        'isPaused': isPaused,
        'timestamp': timestamp.toIso8601String(),
      });

  static List<int> timeControl({required bool pause}) => _encode({
        'type': DebateEventType.timeControl.wire,
        'action': pause ? 'pause' : 'resume',
      });

  static List<int> speakerState({
    required String speakerSid,
    required String role,
    required String side,
    required int index,
  }) =>
      _encode({
        'type': DebateEventType.speakerState.wire,
        'speakerSid': speakerSid,
        'role': role,
        'side': side,
        'index': index,
      });

  static List<int> speakerOrderUpdate({
    required String teamId,
    required List<String> orderedSpeakerIds,
    String? replySpeakerId,
  }) =>
      _encode({
        'type': DebateEventType.speakerOrderUpdate.wire,
        'teamId': teamId,
        'orderedSpeakerIds': orderedSpeakerIds,
        'replySpeakerId': replySpeakerId,
      });

  static List<int> forceMute(String targetSid) =>
      _encode({'type': DebateEventType.forceMute.wire, 'targetSid': targetSid});

  static List<int> forceCameraOff(String targetSid) =>
      _encode({'type': DebateEventType.forceCameraOff.wire, 'targetSid': targetSid});

  static List<int> teamChat({
    required String teamId,
    required String senderId,
    required String senderName,
    required String message,
    required int ts,
  }) =>
      _encode({
        'type': DebateEventType.teamChat.wire,
        'teamId': teamId,
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'ts': ts,
      });

  static List<int> lobbyMode({required bool enabled}) =>
      _encode({'type': DebateEventType.lobbyMode.wire, 'enabled': enabled});

  static List<int> publishLock({
    required bool muteAll,
    required List<String> lockedIds,
    bool cameraAllOff = false,
    List<String> cameraLockedIds = const [],
  }) =>
      _encode({
        'type': DebateEventType.publishLock.wire,
        'muteAll': muteAll,
        'lockedIds': lockedIds,
        'cameraAllOff': cameraAllOff,
        'cameraLockedIds': cameraLockedIds,
      });

  static List<int> shareResult() => _encode({'type': DebateEventType.shareResult.wire});

  static List<int> closeRoom() => _encode({'type': DebateEventType.closeRoom.wire});

  // ── Decoder ──────────────────────────────────────────────────────────────

  /// Parses raw bytes received from the data channel. Returns null for
  /// unknown/invalid payloads so callers can ignore them safely.
  static DebateEvent? decode(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) return null;
      final type = DebateEventType.fromWire(decoded['type'] as String?);
      if (type == null) return null;
      return DebateEvent(type, decoded);
    } catch (_) {
      return null;
    }
  }
}
