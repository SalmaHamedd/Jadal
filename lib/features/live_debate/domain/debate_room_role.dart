/// The user's role **within a specific room**, from the token `role_in_room`
/// (and `live-state.rooms[x].role_if_joined`). UI gating keys off this, NOT the
/// user's global account role (§8, docs §C/§D).
enum DebateRoomRole {
  judgeChair('judge_chair'),
  judgePanel('judge_panel'),
  debater('debater'),
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
}
