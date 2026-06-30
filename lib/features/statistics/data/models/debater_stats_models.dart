import '../../../../core/function/json_utils.dart';

/// Models for the read-only "Debater Statistics API" (5 endpoints). Every
/// response is the `data` payload of the standard `{success,message,data}`
/// envelope. Scores are on the platform's 0–100 scale; win-rates / best-speaker
/// rates are 0–1 floats.

/// Which of the five stats is on screen. The first three share the bucketed
/// series shape; ranking and improvement have their own.
enum StatKind { winRate, avgScore, bestSpeaker, ranking, improvement }

/// Time bucket for the chart stats (1, 2, 2.5).
enum StatsGroupBy { none, year, month }

extension StatsGroupByWire on StatsGroupBy {
  String get wire => switch (this) {
        StatsGroupBy.none => 'none',
        StatsGroupBy.year => 'year',
        StatsGroupBy.month => 'month',
      };
}

/// Which filter dimension becomes the parallel bars.
enum StatsSeries { none, frameworks, positions, teams }

extension StatsSeriesWire on StatsSeries {
  String get wire => name; // none|frameworks|positions|teams
}

/// Ranking ordering for stat 3.
enum RankingMode { top, bottom, latest, earliest }

extension RankingModeWire on RankingMode {
  String get wire => name; // top|bottom|latest|earliest
}

/// The shared filter bar that feeds all five endpoints. `from`/`to` are
/// `YYYY-MM`. group_by/series are only sent for the chart stats.
class StatsFilter {
  final String? from;
  final String? to;
  final StatsGroupBy groupBy;
  final List<int> frameworks;
  final List<String> positions; // slot/role/side codes (e.g. P1, 1, P)
  final List<String> teams; // team ids and/or "RANDOM"
  final StatsSeries series;

  const StatsFilter({
    this.from,
    this.to,
    this.groupBy = StatsGroupBy.none,
    this.frameworks = const [],
    this.positions = const [],
    this.teams = const [],
    this.series = StatsSeries.none,
  });

  StatsFilter copyWith({
    String? from,
    String? to,
    bool clearFrom = false,
    bool clearTo = false,
    StatsGroupBy? groupBy,
    List<int>? frameworks,
    List<String>? positions,
    List<String>? teams,
    StatsSeries? series,
  }) {
    return StatsFilter(
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      groupBy: groupBy ?? this.groupBy,
      frameworks: frameworks ?? this.frameworks,
      positions: positions ?? this.positions,
      teams: teams ?? this.teams,
      series: series ?? this.series,
    );
  }

  /// Common query params. [includeGrouping] adds group_by/series — omitted for
  /// ranking & improvement, which ignore both.
  Map<String, String> toQuery({bool includeGrouping = true}) {
    return {
      'from': ?from,
      'to': ?to,
      if (frameworks.isNotEmpty) 'frameworks': frameworks.join(','),
      if (positions.isNotEmpty) 'positions': positions.join(','),
      if (teams.isNotEmpty) 'teams': teams.join(','),
      if (includeGrouping) 'group_by': groupBy.wire,
      if (includeGrouping && series != StatsSeries.none) 'series': series.wire,
    };
  }
}

/// One bar within a bucket. win-rate/avg-score fill [value]; best-speaker fills
/// [count] + [rate]. Every entry carries its [nDebates] trust count.
class StatSeriesEntry {
  final String key;
  final String label;
  final double? value;
  final int? count;
  final double? rate;
  final int nDebates;

  const StatSeriesEntry({
    required this.key,
    required this.label,
    this.value,
    this.count,
    this.rate,
    required this.nDebates,
  });

  factory StatSeriesEntry.fromJson(Map<String, dynamic> j) => StatSeriesEntry(
        key: asString(j['key']) ?? '',
        label: asString(j['label']) ?? '',
        value: asDouble(j['value']),
        count: asInt(j['count']),
        rate: asDouble(j['rate']),
        nDebates: asInt(j['n_debates']) ?? 0,
      );

  /// The 0–100 number the chart plots for [kind]: win-rate & best-speaker rate
  /// are 0–1 → scaled to a percentage; avg-score is already 0–100.
  double plotted(StatKind kind) => switch (kind) {
        StatKind.winRate => (value ?? 0) * 100,
        StatKind.bestSpeaker => (rate ?? 0) * 100,
        StatKind.avgScore => value ?? 0,
        _ => value ?? 0,
      };

  /// A short caption shown on/under the bar.
  String caption(StatKind kind) => switch (kind) {
        StatKind.winRate => '${(plotted(kind)).round()}%',
        StatKind.bestSpeaker => '${count ?? 0}× · ${(plotted(kind)).round()}%',
        StatKind.avgScore => (value ?? 0).toStringAsFixed(1),
        _ => (value ?? 0).toStringAsFixed(1),
      };
}

class StatBucket {
  final String label;
  final List<StatSeriesEntry> series;
  const StatBucket({required this.label, required this.series});

  factory StatBucket.fromJson(Map<String, dynamic> j) => StatBucket(
        label: asString(j['label']) ?? '',
        series: asMapList(j['series']).map(StatSeriesEntry.fromJson).toList(),
      );
}

/// Shape shared by win-rate, avg-score and best-speaker (stats 1, 2, 2.5).
class BucketedStat {
  final String stat;
  final String grouping;
  final String seriesDimension;
  final List<StatBucket> buckets;
  final int totalNDebates;

  const BucketedStat({
    required this.stat,
    required this.grouping,
    required this.seriesDimension,
    required this.buckets,
    required this.totalNDebates,
  });

  factory BucketedStat.fromJson(Map<String, dynamic> j) => BucketedStat(
        stat: asString(j['stat']) ?? '',
        grouping: asString(j['grouping']) ?? '',
        seriesDimension: asString(j['series_dimension']) ?? 'none',
        buckets: asMapList(j['buckets']).map(StatBucket.fromJson).toList(),
        totalNDebates: asInt(j['total_n_debates']) ?? 0,
      );

  /// Distinct series (key,label) across all buckets, first-seen order — used for
  /// the legend and to keep bar colours stable per series.
  List<({String key, String label})> get seriesKeys {
    final seen = <String>{};
    final out = <({String key, String label})>[];
    for (final b in buckets) {
      for (final s in b.series) {
        if (seen.add(s.key)) out.add((key: s.key, label: s.label));
      }
    }
    return out;
  }

  bool get isEmpty => buckets.isEmpty;
}

/// One row of the score-ranking list (stat 3).
class RankingEntry {
  final int debateId;
  final String debateDate;
  final String motionText;
  final int? frameworkId;
  final String? frameworkLabel;
  final String side;
  final List<String> positionsHeld;
  final int? teamId;
  final String? teamLabel;
  final double normalizedScore;
  final int? rawMainScore;
  final int? rawReplyScore;
  final String? winningSide;
  final bool debateWon;

  const RankingEntry({
    required this.debateId,
    required this.debateDate,
    required this.motionText,
    this.frameworkId,
    this.frameworkLabel,
    required this.side,
    required this.positionsHeld,
    this.teamId,
    this.teamLabel,
    required this.normalizedScore,
    this.rawMainScore,
    this.rawReplyScore,
    this.winningSide,
    required this.debateWon,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> j) {
    final fw = asMap(j['framework']);
    final team = asMap(j['team']);
    return RankingEntry(
      debateId: asInt(j['debate_id']) ?? 0,
      debateDate: asString(j['debate_date']) ?? '',
      motionText: asString(j['motion_text']) ?? '',
      frameworkId: asInt(fw?['id']),
      frameworkLabel: asString(fw?['label']),
      side: asString(j['side']) ?? '',
      positionsHeld: asStringList(j['positions_held']),
      teamId: asInt(team?['id']),
      teamLabel: asString(team?['label']),
      normalizedScore: asDouble(j['normalized_score']) ?? 0,
      rawMainScore: asInt(j['raw_main_score']),
      rawReplyScore: asInt(j['raw_reply_score']),
      winningSide: asString(j['winning_side']),
      debateWon: asBool(j['debate_won']),
    );
  }
}

class ScoreRanking {
  final String rankingMode;
  final int limit;
  final int totalQualifyingDebates;
  final List<RankingEntry> entries;

  const ScoreRanking({
    required this.rankingMode,
    required this.limit,
    required this.totalQualifyingDebates,
    required this.entries,
  });

  factory ScoreRanking.fromJson(Map<String, dynamic> j) => ScoreRanking(
        rankingMode: asString(j['ranking_mode']) ?? 'top',
        limit: asInt(j['limit']) ?? 5,
        totalQualifyingDebates: asInt(j['total_qualifying_debates']) ?? 0,
        entries: asMapList(j['entries']).map(RankingEntry.fromJson).toList(),
      );
}

class ImprovementComponents {
  final double slopeScore;
  final double slopeWinrate;
  final double consistency;
  final double scoreNorm;
  final double winrateNorm;
  final double consistencyNorm;

  const ImprovementComponents({
    required this.slopeScore,
    required this.slopeWinrate,
    required this.consistency,
    required this.scoreNorm,
    required this.winrateNorm,
    required this.consistencyNorm,
  });

  factory ImprovementComponents.fromJson(Map<String, dynamic> j) =>
      ImprovementComponents(
        slopeScore: asDouble(j['slope_score']) ?? 0,
        slopeWinrate: asDouble(j['slope_winrate']) ?? 0,
        consistency: asDouble(j['consistency']) ?? 0,
        scoreNorm: asDouble(j['score_norm']) ?? 0,
        winrateNorm: asDouble(j['winrate_norm']) ?? 0,
        consistencyNorm: asDouble(j['consistency_norm']) ?? 0,
      );
}

class ImprovementBucket {
  final String label;
  final double avgScore;
  final double winRate;
  final int nDebates;

  const ImprovementBucket({
    required this.label,
    required this.avgScore,
    required this.winRate,
    required this.nDebates,
  });

  factory ImprovementBucket.fromJson(Map<String, dynamic> j) => ImprovementBucket(
        label: asString(j['label']) ?? '',
        avgScore: asDouble(j['avg_score']) ?? 0,
        winRate: asDouble(j['win_rate']) ?? 0,
        nDebates: asInt(j['n_debates']) ?? 0,
      );
}

/// Stat 5 — a single signed improvement index (~−50..+50) + a band, with a
/// monthly/yearly sparkline. [index] is null when there isn't enough history.
class ImprovementStat {
  final String granularity;
  final double? index;
  final String? band;
  final ImprovementComponents? components;
  final List<ImprovementBucket> buckets;
  final int totalNDebates;
  final String? reason;

  const ImprovementStat({
    required this.granularity,
    this.index,
    this.band,
    this.components,
    required this.buckets,
    required this.totalNDebates,
    this.reason,
  });

  factory ImprovementStat.fromJson(Map<String, dynamic> j) => ImprovementStat(
        granularity: asString(j['granularity']) ?? 'monthly',
        index: asDouble(j['index']),
        band: asString(j['band']),
        components: asMap(j['components']) == null
            ? null
            : ImprovementComponents.fromJson(asMap(j['components'])!),
        buckets: asMapList(j['buckets']).map(ImprovementBucket.fromJson).toList(),
        totalNDebates: asInt(j['total_n_debates']) ?? 0,
        reason: asString(j['reason']),
      );

  bool get hasEnoughHistory => index != null;
}
