class PhaseConfig {
  final String? name;
  final int? orderIndex;
  final int? durationSeconds;
  final String? role;

  const PhaseConfig({this.name, this.orderIndex, this.durationSeconds, this.role});

  factory PhaseConfig.fromJson(Map<String, dynamic> j) => PhaseConfig(
        name: j['name'] as String?,
        orderIndex: (j['order_index'] as num?)?.toInt(),
        durationSeconds: (j['duration_seconds'] as num?)?.toInt(),
        role: j['role'] as String?,
      );
}

/// Backend debate format, parsed **defensively from both representations** (§6):
///
///  - `live-state.format` — an object: `{speech_time_seconds, has_reply_speech,
///    reply_time_seconds, motion_reveal_offset_hours, prep_rooms_open_offset_hours,
///    speakers_per_side, total_stages}`.
///  - `GET /debates[].format` — `{id, name, description, phase_config}` where
///    **`phase_config` is either a List of phases OR a Map** with the same object
///    shape as `live-state.format`.
///
/// ⚠️ Never assume one shape — branch on `is List` / `is Map`. All scalar
/// accessors are nullable; [phases] is possibly empty. Durations can be `null`
/// for seeded/template debates, so guard before using them.
class DebateFormatModel {
  final int? id;
  final String? name;
  final String? description;

  // Object/Map shape (live-state.format, or phase_config-as-Map).
  final int? speechTimeSeconds;
  final bool? hasReplySpeech;
  final int? replyTimeSeconds;
  final num? motionRevealOffsetHours;
  final num? prepRoomsOpenOffsetHours;
  final int? speakersPerSide;
  final int? totalStages;

  // List shape (phase_config-as-List).
  final List<PhaseConfig> phases;

  const DebateFormatModel({
    this.id,
    this.name,
    this.description,
    this.speechTimeSeconds,
    this.hasReplySpeech,
    this.replyTimeSeconds,
    this.motionRevealOffsetHours,
    this.prepRoomsOpenOffsetHours,
    this.speakersPerSide,
    this.totalStages,
    this.phases = const [],
  });

  /// Parses format data from either `live-state.format` or
  /// `GET /debates[].format` — as of the sprinkles-round backend response,
  /// live-state.format is a strict superset of the debate-list shape (it now
  /// also carries `id`/`name`/`description`/`phase_config`), so both shapes
  /// can be parsed the same way: flat top-level scalars are read directly,
  /// and `phase_config` is handled polymorphically (List → [phases], Map →
  /// fallback scalars for the older debate-list shape where they only ever
  /// lived nested inside `phase_config`).
  factory DebateFormatModel.fromJson(Map<String, dynamic> j) {
    final pc = j['phase_config'];
    List<PhaseConfig> phases = const [];
    int? speech, reply, speakers, stages;
    bool? hasReply;
    num? motionOffset, prepOffset;
    if (pc is List) {
      phases = pc
          .whereType<Map>()
          .map((e) => PhaseConfig.fromJson(e.cast<String, dynamic>()))
          .toList();
    } else if (pc is Map) {
      final m = pc.cast<String, dynamic>();
      speech = (m['speech_time_seconds'] as num?)?.toInt();
      reply = (m['reply_time_seconds'] as num?)?.toInt();
      hasReply = m['has_reply_speech'] as bool?;
      motionOffset = m['motion_reveal_offset_hours'] as num?;
      prepOffset = m['prep_rooms_open_offset_hours'] as num?;
      speakers = (m['speakers_per_side'] as num?)?.toInt();
      stages = (m['total_stages'] as num?)?.toInt();
    }
    return DebateFormatModel(
      id: (j['id'] as num?)?.toInt(),
      name: j['name'] as String?,
      description: j['description'] as String?,
      speechTimeSeconds: (j['speech_time_seconds'] as num?)?.toInt() ?? speech,
      hasReplySpeech: j['has_reply_speech'] as bool? ?? hasReply,
      replyTimeSeconds: (j['reply_time_seconds'] as num?)?.toInt() ?? reply,
      motionRevealOffsetHours: j['motion_reveal_offset_hours'] as num? ?? motionOffset,
      prepRoomsOpenOffsetHours: j['prep_rooms_open_offset_hours'] as num? ?? prepOffset,
      speakersPerSide: (j['speakers_per_side'] as num?)?.toInt() ?? speakers,
      totalStages: (j['total_stages'] as num?)?.toInt() ?? stages,
      phases: phases,
    );
  }

  /// Parses `live-state.format`. Kept as a named alias of [fromJson] so call
  /// sites stay expressive about which payload they're reading.
  factory DebateFormatModel.fromLiveState(Map<String, dynamic> j) =>
      DebateFormatModel.fromJson(j);

  /// Parses `GET /debates[].format`. Alias of [fromJson] — see its doc.
  factory DebateFormatModel.fromDebateList(Map<String, dynamic> j) =>
      DebateFormatModel.fromJson(j);

  /// Whether this format includes a reply speech (from either representation).
  bool get hasReply => hasReplySpeech ?? false;

  /// Converts a backend `*_offset_hours` value (fractional hours, e.g. `0.5`
  /// = 30 minutes — confirmed by backend) into a [Duration]. Route every
  /// offset field through this one helper instead of ad-hoc per-field math.
  static Duration hoursOffsetToDuration(num hours) =>
      Duration(seconds: (hours * 3600).round());
}
