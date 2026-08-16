/// The user's role inside one room, taken from the token's `role_in_room` or
/// `live-state.rooms[x].role_if_joined`. UI gating uses this, not the user's
/// global account role.
enum DebateRoomRole {
  judgeChair('judge_chair'),
  judgePanel('judge_panel'),
  debater('debater'),
  // The backend sends three interchangeable debater spellings; all of them mean
  // the same thing here.
  debaterMember('debater_member'),
  debaterSpeaker('debater_speaker'),
  trainer('trainer'),
  viewer('viewer'),

  /// Someone who opened a share link without an account. Watch-only: no
  /// publishing, no controls, no sharing.
  guest('guest'),
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

  bool get isDebater =>
      this == debater || this == debaterMember || this == debaterSpeaker;

  bool get isGuest => this == guest;
}
