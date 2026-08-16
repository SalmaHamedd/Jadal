/// Public leaderboards.
/// `GET /leaderboards/debaters?metric=…&limit=10` and
/// `GET /leaderboards/teams?metric=…&limit=10`, both returning
/// `data: { metric, entries: [{ rank, …subject fields…, value }] }`.
/// Debater entries carry `user_id/name/avatar_url`; team entries carry
/// `team_id/team_name/logo_url` (logo_url is always null today — teams have
/// no logo column; the UI falls back to an initial).
library;

enum LeaderboardScope { debaters, teams }

/// Optional leaderboard filters. Constraints:
/// `positions` and `frameworks` are mutually exclusive (422); `positions` is
/// rejected on the teams leaderboard (422); and `metric=points` rejects every
/// filter (Elo is order-dependent) — the repository strips them for points.
class LeaderboardFilter {
  final String? from; // YYYY-MM
  final String? to; // YYYY-MM
  final List<String> positions;
  final List<int> frameworks;

  const LeaderboardFilter({
    this.from,
    this.to,
    this.positions = const [],
    this.frameworks = const [],
  });

  bool get isEmpty =>
      from == null && to == null && positions.isEmpty && frameworks.isEmpty;

  LeaderboardFilter copyWith({
    String? from,
    String? to,
    bool clearFrom = false,
    bool clearTo = false,
    List<String>? positions,
    List<int>? frameworks,
  }) {
    return LeaderboardFilter(
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      positions: positions ?? this.positions,
      frameworks: frameworks ?? this.frameworks,
    );
  }

  Map<String, String> toQuery({required LeaderboardScope scope}) => {
        'from': ?from,
        'to': ?to,
        // Positions are meaningless for a team aggregate — never sent there.
        if (positions.isNotEmpty && scope == LeaderboardScope.debaters)
          'positions': positions.join(','),
        if (frameworks.isNotEmpty) 'frameworks': frameworks.join(','),
      };
}

enum LeaderboardMetric {
  points('points'),
  winRate('win_rate'),
  avgScore('avg_score'),
  bestSpeaker('best_speaker'),
  improvement('improvement');

  final String wire;
  const LeaderboardMetric(this.wire);

  /// `best_speaker` has no team equivalent — the endpoint 422s on it.
  bool availableFor(LeaderboardScope scope) =>
      scope == LeaderboardScope.debaters || this != LeaderboardMetric.bestSpeaker;

  static List<LeaderboardMetric> forScope(LeaderboardScope scope) =>
      values.where((m) => m.availableFor(scope)).toList();
}

class LeaderboardEntry {
  final int rank;
  final int subjectId;
  final String name;
  final String? imageUrl;
  final num value;

  const LeaderboardEntry({
    required this.rank,
    required this.subjectId,
    required this.name,
    required this.imageUrl,
    required this.value,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j, LeaderboardScope scope) {
    final isTeam = scope == LeaderboardScope.teams;
    return LeaderboardEntry(
      rank: (j['rank'] as num?)?.toInt() ?? 0,
      subjectId: ((isTeam ? j['team_id'] : j['user_id']) as num?)?.toInt() ?? 0,
      name: ((isTeam ? j['team_name'] : j['name']) ?? '').toString(),
      imageUrl: (isTeam ? j['logo_url'] : j['avatar_url']) as String?,
      value: (j['value'] as num?) ?? 0,
    );
  }
}

class Leaderboard {
  final LeaderboardScope scope;
  final LeaderboardMetric metric;
  final List<LeaderboardEntry> entries;

  const Leaderboard({required this.scope, required this.metric, required this.entries});

  factory Leaderboard.fromJson(
    Map<String, dynamic> data,
    LeaderboardScope scope,
    LeaderboardMetric metric,
  ) =>
      Leaderboard(
        scope: scope,
        metric: metric,
        entries: [
          for (final e in (data['entries'] as List? ?? const []))
            if (e is Map) LeaderboardEntry.fromJson(e.cast<String, dynamic>(), scope),
        ],
      );
}
