/// Lifecycle status of a debate, as returned by `GET /debates` and
/// `live-state.debate.status`. Drives the debate-list stage tabs (§13) and the
/// join/cancel gating.
enum DebateStatus {
  scheduled('scheduled'),
  announced('announced'),
  teamsSelected('teams-selected'),
  live('live'),
  completed('completed'),
  cancelled('cancelled'),
  unknown('unknown');

  final String wire;
  const DebateStatus(this.wire);

  static DebateStatus fromWire(String? raw) {
    for (final s in DebateStatus.values) {
      if (s.wire == raw) return s;
    }
    return DebateStatus.unknown;
  }
}
