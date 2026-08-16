import '../../../../core/function/json_utils.dart';

/// One entry in the coach's team picker.
class TrainerTeam {
  final int id;
  final String name;
  final bool isActive;
  final int membersCount;
  final bool isRandom;

  const TrainerTeam({
    required this.id,
    required this.name,
    required this.isActive,
    required this.membersCount,
    required this.isRandom,
  });

  factory TrainerTeam.fromJson(Map<String, dynamic> j) => TrainerTeam(
        id: asInt(j['id']) ?? 0,
        name: asString(j['name']) ?? '',
        isActive: asBool(j['is_active']),
        membersCount: asInt(j['members_count']) ?? 0,
        isRandom: asBool(j['is_random']),
      );
}

/// One member of a line-up. [isCurrentMember] is false for someone
/// who has since left the team; their historical line-ups still appear, so the
/// coach's history doesn't silently rewrite itself.
class CombinationMember {
  final int userId;
  final String name;
  final String? avatarUrl;
  final bool isCurrentMember;

  const CombinationMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.isCurrentMember,
  });

  factory CombinationMember.fromJson(Map<String, dynamic> j) =>
      CombinationMember(
        userId: asInt(j['user_id']) ?? 0,
        name: asString(j['name']) ?? '',
        avatarUrl: asString(j['avatar_url']),
        // Absent on older payloads → assume still on the team.
        isCurrentMember: j['is_current_member'] == null
            ? true
            : asBool(j['is_current_member']),
      );
}

/// One distinct line-up and how it performed. The key is the sorted set of user
/// ids, so slot shuffling doesn't fragment the sample (order-insensitive).
class TeamCombination {
  final String key;
  final int size;
  final List<CombinationMember> members;
  final int nDebates;
  final int wins;
  final double? winRate;
  final double? avgScore;
  final DateTime? lastDebateAt;

  const TeamCombination({
    required this.key,
    required this.size,
    required this.members,
    required this.nDebates,
    required this.wins,
    this.winRate,
    this.avgScore,
    this.lastDebateAt,
  });

  factory TeamCombination.fromJson(Map<String, dynamic> j) {
    final members =
        asMapList(j['members']).map(CombinationMember.fromJson).toList();
    return TeamCombination(
      key: asString(j['key']) ?? '',
      size: asInt(j['size']) ?? members.length,
      members: members,
      nDebates: asInt(j['n_debates']) ?? 0,
      wins: asInt(j['wins']) ?? 0,
      winRate: asDouble(j['win_rate']),
      avgScore: asDouble(j['avg_score']),
      lastDebateAt: DateTime.tryParse(asString(j['last_debate_at']) ?? ''),
    );
  }

  /// The value the list is ranked by, on the metric currently in view.
  double? valueFor(CombinationMetric metric) =>
      metric == CombinationMetric.winRate ? winRate : avgScore;
}

enum CombinationMetric {
  winRate('win_rate'),
  avgScore('avg_score');

  final String wire;
  const CombinationMetric(this.wire);
}

/// The team's own numbers over the same filtered window, so each line-up can be
/// shown as a delta ("+29% above the team average") rather than a bare figure.
class TeamBaseline {
  final int nDebates;
  final double? winRate;
  final double? avgScore;

  const TeamBaseline({
    required this.nDebates,
    this.winRate,
    this.avgScore,
  });

  factory TeamBaseline.fromJson(Map<String, dynamic>? j) => TeamBaseline(
        nDebates: asInt(j?['n_debates']) ?? 0,
        winRate: asDouble(j?['win_rate']),
        avgScore: asDouble(j?['avg_score']),
      );

  double? valueFor(CombinationMetric metric) =>
      metric == CombinationMetric.winRate ? winRate : avgScore;
}

/// `GET /teams/{id}/stats/combinations`. Empty windows come back `200` with
/// `combinations: []` and a [reason] — never a 404/422.
class TeamCombinationsStat {
  final int teamId;
  final String teamName;
  final CombinationMetric metric;

  /// Null when the window contains line-ups of MIXED sizes; read each
  /// combination's own `size` in that case.
  final int? combinationSize;
  final int totalDebatesConsidered;
  final int distinctCombinations;
  final int minDebates;
  final List<TeamCombination> combinations;
  final TeamBaseline baseline;
  final String? reason;

  const TeamCombinationsStat({
    required this.teamId,
    required this.teamName,
    required this.metric,
    this.combinationSize,
    required this.totalDebatesConsidered,
    required this.distinctCombinations,
    required this.minDebates,
    required this.combinations,
    required this.baseline,
    this.reason,
  });

  factory TeamCombinationsStat.fromJson(Map<String, dynamic> j) =>
      TeamCombinationsStat(
        teamId: asInt(j['team_id']) ?? 0,
        teamName: asString(j['team_name']) ?? '',
        metric: asString(j['metric']) == 'avg_score'
            ? CombinationMetric.avgScore
            : CombinationMetric.winRate,
        combinationSize: asInt(j['combination_size']),
        totalDebatesConsidered: asInt(j['total_debates_considered']) ?? 0,
        distinctCombinations: asInt(j['distinct_combinations']) ?? 0,
        minDebates: asInt(j['min_debates']) ?? 2,
        combinations:
            asMapList(j['combinations']).map(TeamCombination.fromJson).toList(),
        baseline: TeamBaseline.fromJson(asMap(j['team_baseline'])),
        reason: asString(j['reason']),
      );

  /// True when the returned list is a subset of what exists, because the rest
  /// fell below `min_debates` — worth telling the coach explicitly.
  bool get isTruncated =>
      distinctCombinations > combinations.length && combinations.isNotEmpty;

  /// Line-ups in this window vary in size, so the UI groups by size.
  bool get hasMixedSizes => combinationSize == null && combinations.isNotEmpty;
}
