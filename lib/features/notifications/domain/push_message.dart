/// Push-notification payload model.
/// The backend sends every value in the FCM `data` block as a **string** (an
/// FCM constraint), always including `type`, plus at most one entity id. This
/// parses that into something the router can switch on safely.
/// Deliberately tolerant: an unrecognised `type`, or a known type whose id is
/// missing or unparseable, degrades to [PushType.unknown] rather than throwing.
/// A push that cannot be routed must never crash the app — the backend can add
/// a new type at any time and older installs have to survive it.
library;

/// The seven live notification types.
/// `debate_created` is deliberately ABSENT. The backend removed it outright
///: restricting it to "open for registration"
/// was a no-op, because debates are created in `scheduled` — which *is* the
/// registration-open state — so it would still have notified every user on
/// every creation. Nothing will ever arrive with that type; do not add it back
/// without a heads-up from the backend.
enum PushType {
  debateStateChanged('debate_state_changed'),
  debateAccepted('debate_accepted'),
  prepReminder('prep_reminder'),
  motionRevealed('motion_revealed'),
  surveyCreated('survey_created'),
  teamJoinResult('team_join_result'),
  blogWeeklyDigest('blog_weekly_digest'),

  /// Anything we don't recognise — routed to Home.
  unknown('');

  final String wire;
  const PushType(this.wire);

  static PushType fromWire(String? raw) {
    for (final t in PushType.values) {
      if (t != PushType.unknown && t.wire == raw) return t;
    }
    return PushType.unknown;
  }
}

/// Where a [PushMessage] should land.
enum PushDestination { debateDetails, survey, team, blog, home }

/// A parsed push payload.
class PushMessage {
  final PushType type;

  /// The single entity id carried by this type, already parsed. Null when the
  /// type carries none ([PushType.blogWeeklyDigest]) or the value was missing
  /// or malformed.
  final int? entityId;

  /// `team_join_result` only: `accepted` | `refused`. The backend defaults a
  /// missing value to `refused` on its side; we keep whatever arrives.
  final String? result;

  const PushMessage({required this.type, this.entityId, this.result});

  /// Builds from an FCM `data` map. Values arrive as strings, but this accepts
  /// any type defensively — a future backend change to numeric ids would
  /// otherwise silently break routing.
  factory PushMessage.fromData(Map<String, dynamic> data) {
    final type = PushType.fromWire(data['type']?.toString());
    int? idFor(String key) {
      final raw = data[key];
      if (raw == null) return null;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw.toString());
    }

    return PushMessage(
      type: type,
      entityId: switch (type) {
        PushType.debateStateChanged ||
        PushType.debateAccepted ||
        PushType.prepReminder ||
        PushType.motionRevealed => idFor('debate_id'),
        PushType.surveyCreated => idFor('survey_id'),
        PushType.teamJoinResult => idFor('team_id'),
        PushType.blogWeeklyDigest || PushType.unknown => null,
      },
      result: data['result']?.toString(),
    );
  }

  /// Screen this message opens. Types that need an id but arrived without a
  /// usable one fall back to Home rather than pushing a screen that would
  /// immediately fail to load.
  PushDestination get destination {
    switch (type) {
      case PushType.debateStateChanged:
      case PushType.debateAccepted:
      case PushType.prepReminder:
      case PushType.motionRevealed:
        return entityId == null ? PushDestination.home : PushDestination.debateDetails;
      case PushType.surveyCreated:
        return entityId == null ? PushDestination.home : PushDestination.survey;
      case PushType.teamJoinResult:
        return entityId == null ? PushDestination.home : PushDestination.team;
      case PushType.blogWeeklyDigest:
        return PushDestination.blog;
      case PushType.unknown:
        return PushDestination.home;
    }
  }

  @override
  String toString() =>
      'PushMessage(type: ${type.wire}, entityId: $entityId, result: $result)';
}
