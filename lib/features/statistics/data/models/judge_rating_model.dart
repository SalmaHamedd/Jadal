import '../../../../core/function/json_utils.dart';

/// MF_FU §5 — the judge's average rating received.
///
/// Source data is the existing `POST /feedback` `rating_judgement` rows. The
/// backend confirmed `to_user_id` is **enforced** on those (and validated to be
/// a judge *of that debate*), so a rating always belongs to one named judge —
/// multi-judge panels need no special handling, and nothing here is ever a
/// panel average presented as an individual's score.
///
/// Aggregates only: no rater ids, no names, no free-text comments.
class JudgeRatingStat {
  final int judgeId;
  final String grouping;
  final int scaleMin;
  final int scaleMax;

  final double? avgRating;
  final int ratingsCount;
  final int debatesRated;
  final int debatesJudged;
  final double? coverage;

  /// Always contains **every** point on the scale, including zeros, so a fixed
  /// histogram renders without filling gaps client-side.
  final Map<int, int> distribution;

  final List<JudgeRatingBucket> buckets;

  /// Mean across all OTHER judges in the same window — excludes this judge, so
  /// a high-volume judge isn't largely compared against themselves. Null when
  /// there is no peer group.
  final double? peerAverage;

  /// `no_ratings_received` (judged, nobody rated) vs `no_debates_judged`
  /// (never judged) — different states that deserve different copy.
  final String? reason;

  const JudgeRatingStat({
    required this.judgeId,
    required this.grouping,
    required this.scaleMin,
    required this.scaleMax,
    this.avgRating,
    required this.ratingsCount,
    required this.debatesRated,
    required this.debatesJudged,
    this.coverage,
    required this.distribution,
    required this.buckets,
    this.peerAverage,
    this.reason,
  });

  factory JudgeRatingStat.fromJson(Map<String, dynamic> j) {
    final scale = asMap(j['rating_scale']);
    final totals = asMap(j['totals']);
    final dist = asMap(totals?['distribution']) ?? const {};
    return JudgeRatingStat(
      judgeId: asInt(j['judge_id']) ?? 0,
      grouping: asString(j['grouping']) ?? 'none',
      scaleMin: asInt(scale?['min']) ?? 1,
      scaleMax: asInt(scale?['max']) ?? 5,
      avgRating: asDouble(totals?['avg_rating']),
      ratingsCount: asInt(totals?['ratings_count']) ?? 0,
      debatesRated: asInt(totals?['debates_rated']) ?? 0,
      debatesJudged: asInt(totals?['debates_judged']) ?? 0,
      coverage: asDouble(totals?['coverage']),
      distribution: {
        for (final e in dist.entries)
          if (int.tryParse(e.key.toString()) != null)
            int.parse(e.key.toString()): asInt(e.value) ?? 0,
      },
      buckets: asMapList(j['buckets']).map(JudgeRatingBucket.fromJson).toList(),
      peerAverage: asDouble(j['peer_average']),
      reason: asString(j['reason']),
    );
  }

  bool get hasRatings => ratingsCount > 0 && avgRating != null;

  /// Below this the average is shown but captioned as not yet meaningful.
  /// The threshold is ours, not the backend's — it always returns the average
  /// whenever at least one rating exists.
  static const int meaningfulThreshold = 5;

  bool get isLowSample => hasRatings && ratingsCount < meaningfulThreshold;

  /// Signed difference against the peer group, or null when there is none.
  double? get peerDelta => (avgRating != null && peerAverage != null)
      ? avgRating! - peerAverage!
      : null;

  int get maxDistributionCount =>
      distribution.values.fold(0, (a, b) => a > b ? a : b);
}

class JudgeRatingBucket {
  final String label;

  /// Null (not 0) for a period with no ratings — "nobody rated me" is not
  /// "everybody rated me zero".
  final double? avgRating;
  final int ratingsCount;
  final int debatesRated;

  const JudgeRatingBucket({
    required this.label,
    this.avgRating,
    required this.ratingsCount,
    required this.debatesRated,
  });

  factory JudgeRatingBucket.fromJson(Map<String, dynamic> j) =>
      JudgeRatingBucket(
        label: asString(j['label']) ?? '',
        avgRating: asDouble(j['avg_rating']),
        ratingsCount: asInt(j['ratings_count']) ?? 0,
        debatesRated: asInt(j['debates_rated']) ?? 0,
      );
}
