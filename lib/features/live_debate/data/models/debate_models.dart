// Plain mock models for the live-debate feature.
// These are intentionally swappable: a real backend (or a real
// `MockLiveDebateData` replacement) can produce the same shapes later.
// Kept Flutter-free so they can be reused from data/domain code.

/// The two debate sides. Proposition = blue (left); Opposition = orange (right).
enum DebateSide { proposition, opposition }

extension DebateSideX on DebateSide {
  /// Role prefix used on speaker cards: P1/P2/P3 or O1/O2/O3.
  String get rolePrefix => this == DebateSide.proposition ? 'P' : 'O';

  /// Reply-speech suffix: PR (proposition reply) / OR (opposition reply).
  String get replySuffix => this == DebateSide.proposition ? 'PR' : 'OR';

  DebateSide get other =>
      this == DebateSide.proposition ? DebateSide.opposition : DebateSide.proposition;
}

/// The kinds of room shown in the lobby.
enum DebateRoomType { proposition, opposition, liveDebate, result }

/// Drives prep timing + speech timing. All thresholds in Layout 2 are
/// derived from these — no magic numbers.
class DebateFormat {
  /// Counts from the debate's start time; while it elapses, prep rooms are open.
  final Duration preparationPeriod;

  /// Main speaking time per speaker.
  final Duration speechDuration;

  /// Opening & closing protected windows (POIs unavailable).
  final Duration protectedPeriod;

  /// Grace to finish the last idea after [speechDuration].
  final Duration extraTime;

  /// Whether a reply speech is part of this format.
  final bool replySpeech;

  /// Reply speech duration (used only when [replySpeech] is true).
  final Duration replyDuration;

  /// Optional backend override for the POI protected margin. Absent today
  /// → the manual duration-based rules apply. When present, it replaces them.
  final Duration? poiOffset;

  const DebateFormat({
    required this.preparationPeriod,
    required this.speechDuration,
    required this.protectedPeriod,
    required this.extraTime,
    required this.replySpeech,
    required this.replyDuration,
    this.poiOffset,
  });
}

class Debater {
  final String id; // matches LiveKit participant identity/sid
  final String name;
  final int ranking; // higher = more senior; highest present picks the order

  const Debater({required this.id, required this.name, required this.ranking});
}

class TeamInfo {
  final String teamId;
  final String teamName; // shown in parentheses in the rooms list
  final DebateSide side;
  final List<Debater> debaters;

  const TeamInfo({
    required this.teamId,
    required this.teamName,
    required this.side,
    required this.debaters,
  });

  Debater? debaterById(String id) {
    for (final d in debaters) {
      if (d.id == id) return d;
    }
    return null;
  }
}

class JudgeInfo {
  final String id;
  final String name;
  const JudgeInfo({required this.id, required this.name});
}

// The motion lives in core now: see `lib/core/app_models/motion.dart`
// (`Motion` + `Framework`), shared with the backend live-state and debate list.

class AudienceMember {
  final String id;
  final String name;
  final String role; // localized/descriptive label
  const AudienceMember({required this.id, required this.name, required this.role});
}

/// Speaker order selected during prep (broadcast over the socket; checked by
/// the live room). [orderedSpeakerIds]\[0] is the first speaker, etc.
class SpeakerOrder {
  final List<String> orderedSpeakerIds;

  /// Must be [orderedSpeakerIds]\[0] or \[1] when reply is on.
  final String? replySpeakerId;
  final bool isSet;

  const SpeakerOrder({
    this.orderedSpeakerIds = const [],
    this.replySpeakerId,
    this.isSet = false,
  });

  bool contains(String speakerId) => orderedSpeakerIds.contains(speakerId);

  SpeakerOrder copyWith({
    List<String>? orderedSpeakerIds,
    String? replySpeakerId,
    bool? isSet,
  }) =>
      SpeakerOrder(
        orderedSpeakerIds: orderedSpeakerIds ?? this.orderedSpeakerIds,
        replySpeakerId: replySpeakerId ?? this.replySpeakerId,
        isSet: isSet ?? this.isSet,
      );
}

/// A room in the lobby.
class DebateRoom {
  final DebateRoomType type;
  final String displayName; // localized
  final TeamInfo? team; // for prop/opp rooms
  final List<String> judgeIds; // for live/result rooms
  final String? propTeamId; // for live/result rooms
  final String? oppTeamId; // for live/result rooms

  const DebateRoom({
    required this.type,
    required this.displayName,
    this.team,
    this.judgeIds = const [],
    this.propTeamId,
    this.oppTeamId,
  });
}
