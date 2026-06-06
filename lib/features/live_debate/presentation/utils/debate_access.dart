import '../../data/models/debate_models.dart';

/// How a user enters the live-debate room (§8.1).
enum LiveJoinRole {
  judge,
  participant,
  audience,

  /// Team member, but their team's speaker order is not set yet → must go to
  /// the prep room and pick the order before joining.
  blockedNeedsOrder,
}

/// Pure, easily-reasoned-about access rules for the lobby (§8.1). No Flutter,
/// no side effects — just identity + mock state in, decision out.
abstract class DebateAccess {
  // ── Prop / Opp team rooms ─────────────────────────────────────────────────

  /// Joinable only by that team's debaters (judges never join team rooms).
  static bool canJoinTeamRoom(TeamInfo team, String userId) =>
      team.debaterById(userId) != null;

  /// Prep is available while `now` is within [DebateFormat.preparationPeriod]
  /// of the debate start.
  static bool prepOpen(DebateFormat format, DateTime start, DateTime now) {
    final end = start.add(format.preparationPeriod);
    return !now.isBefore(start) && now.isBefore(end);
  }

  /// Time until prep opens (zero if already open/passed).
  static Duration prepStartsIn(DateTime start, DateTime now) {
    final diff = start.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Time left in the prep window (zero once closed).
  static Duration prepRemaining(DebateFormat format, DateTime start, DateTime now) {
    final end = start.add(format.preparationPeriod);
    final diff = end.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// The highest-ranked debater currently present ("current leader") who gets
  /// the speaker-order control. Reacts to presence — recompute on join/leave.
  static Debater? currentLeader(TeamInfo team, Set<String> presentIds) {
    Debater? leader;
    for (final d in team.debaters) {
      if (!presentIds.contains(d.id)) continue;
      if (leader == null || d.ranking > leader.ranking) leader = d;
    }
    return leader;
  }

  static bool isLeader(TeamInfo team, Set<String> presentIds, String userId) =>
      currentLeader(team, presentIds)?.id == userId;

  // ── Live debate room ───────────────────────────────────────────────────────

  /// The chair is the first judge present, by the sorted order of [judgeIds].
  static String? chairJudgeId(List<String> judgeIds, Set<String> presentIds) {
    for (final id in judgeIds) {
      if (presentIds.contains(id)) return id;
    }
    return null;
  }

  /// Resolves how [userId] enters the live debate, given the order of *their*
  /// team (if they belong to one).
  static LiveJoinRole resolveLiveJoinRole({
    required List<String> judgeIds,
    required TeamInfo propTeam,
    required TeamInfo oppTeam,
    required SpeakerOrder propOrder,
    required SpeakerOrder oppOrder,
    required String userId,
  }) {
    if (judgeIds.contains(userId)) return LiveJoinRole.judge;

    final TeamInfo? team = propTeam.debaterById(userId) != null
        ? propTeam
        : (oppTeam.debaterById(userId) != null ? oppTeam : null);

    if (team == null) return LiveJoinRole.audience; // not in any list

    final order = team.side == DebateSide.proposition ? propOrder : oppOrder;
    if (!order.isSet) return LiveJoinRole.blockedNeedsOrder;
    return order.contains(userId) ? LiveJoinRole.participant : LiveJoinRole.audience;
  }

  // ── Result room ────────────────────────────────────────────────────────────

  /// Open only after the chair marks the debate done.
  static bool resultRoomOpen(bool chairFinished) => chairFinished;

  /// Joinable only by judges who were present in the live room before the chair
  /// marked the debate finished.
  static bool canJoinResultRoom({
    required List<String> judgeIds,
    required String userId,
    required bool chairFinished,
    required Set<String> judgesPresentAtFinish,
  }) {
    if (!chairFinished) return false;
    if (!judgeIds.contains(userId)) return false;
    return judgesPresentAtFinish.contains(userId);
  }
}
