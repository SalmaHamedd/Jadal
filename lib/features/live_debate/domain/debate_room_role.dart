/// The user's role **within a specific room**, from the token `role_in_room`
/// (and `live-state.rooms[x].role_if_joined`). UI gating keys off this, NOT the
/// user's global account role (§8, docs §C/§D).
enum DebateRoomRole {
  judgeChair('judge_chair'),
  judgePanel('judge_panel'),
  debater('debater'),
  // G2: the backend also sends these two debater variants (`role_if_joined` /
  // `role_in_room`). Without them they fell through to `unknown` and anything
  // keyed off the role broke. Treat all three as a debater.
  debaterMember('debater_member'),
  debaterSpeaker('debater_speaker'),
  trainer('trainer'),
  viewer('viewer'),
  unknown('unknown');

  final String wire;
  const DebateRoomRole(this.wire);

  static DebateRoomRole fromWire(String? raw) {
    for (final r in DebateRoomRole.values) {
      if (r.wire == raw) return r;
    }
    return DebateRoomRole.unknown;
  }

  bool get isJudge => this == judgeChair || this == judgePanel;
  bool get isChair => this == judgeChair;

  /// G2: any of the three debater wire values count as a debater for gating
  /// (POI, team chat, spectator check).
  bool get isDebater =>
      this == debater || this == debaterMember || this == debaterSpeaker;
}
