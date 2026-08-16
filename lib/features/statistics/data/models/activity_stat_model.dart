import '../../../../core/function/json_utils.dart';

/// The participation/activity score.
/// `GET /debaters|trainers|judges/{id}/stats/activity?from=&to=&group_by=`
/// returns raw weighted point totals (NOT percentages — no ceiling is defined
/// server-side), bucketed like the other stats, with a per-bucket and total
/// breakdown of the four signals: registration / attendance / viewing /
/// penalty (missed debates).
class ActivitySignal {
  final double points;
  final int count;
  const ActivitySignal({required this.points, required this.count});

  /// Tolerant of both shapes seen in the contract: `{points, count}` per
  /// bucket, and a bare number in `totals.breakdown`.
  factory ActivitySignal.fromJson(dynamic j) {
    if (j is Map) {
      final m = j.cast<String, dynamic>();
      return ActivitySignal(
        points: asDouble(m['points']) ?? 0,
        count: asInt(m['count']) ?? 0,
      );
    }
    if (j is num) return ActivitySignal(points: j.toDouble(), count: 0);
    return const ActivitySignal(points: 0, count: 0);
  }

  static const zero = ActivitySignal(points: 0, count: 0);
}

class ActivityBreakdown {
  final ActivitySignal registration;
  final ActivitySignal attendance;
  final ActivitySignal viewing;
  final ActivitySignal penalty;

  const ActivityBreakdown({
    required this.registration,
    required this.attendance,
    required this.viewing,
    required this.penalty,
  });

  factory ActivityBreakdown.fromJson(Map<String, dynamic>? j) => ActivityBreakdown(
        registration: ActivitySignal.fromJson(j?['registration']),
        attendance: ActivitySignal.fromJson(j?['attendance']),
        viewing: ActivitySignal.fromJson(j?['viewing']),
        penalty: ActivitySignal.fromJson(j?['penalty']),
      );

  static const zero = ActivityBreakdown(
    registration: ActivitySignal.zero,
    attendance: ActivitySignal.zero,
    viewing: ActivitySignal.zero,
    penalty: ActivitySignal.zero,
  );
}

class ActivityBucket {
  final String label;
  final double value;
  final ActivityBreakdown breakdown;

  const ActivityBucket({required this.label, required this.value, required this.breakdown});

  factory ActivityBucket.fromJson(Map<String, dynamic> j) => ActivityBucket(
        label: asString(j['label']) ?? '',
        value: asDouble(j['value']) ?? 0,
        breakdown: ActivityBreakdown.fromJson(asMap(j['breakdown'])),
      );
}

class ActivityStat {
  final String grouping;
  final List<ActivityBucket> buckets;
  final double totalValue;
  final ActivityBreakdown totalBreakdown;

  const ActivityStat({
    required this.grouping,
    required this.buckets,
    required this.totalValue,
    required this.totalBreakdown,
  });

  factory ActivityStat.fromJson(Map<String, dynamic> j) {
    final totals = asMap(j['totals']);
    return ActivityStat(
      grouping: asString(j['grouping']) ?? 'none',
      buckets: asMapList(j['buckets']).map(ActivityBucket.fromJson).toList(),
      totalValue: asDouble(totals?['value']) ?? 0,
      totalBreakdown: ActivityBreakdown.fromJson(asMap(totals?['breakdown'])),
    );
  }

  bool get isEmpty => buckets.isEmpty;
}
