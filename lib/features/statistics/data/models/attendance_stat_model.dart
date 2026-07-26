/// Attendance rate over time for a debater (prep-room), trainer/coach (own
/// team's debates) or judge (assigned debates) — sprinkles §6.5. All three
/// endpoints share this shape: `rate = attended ÷ selected`, with
/// registered-but-never-selected excluded from that denominator and
/// surfaced separately as `totals.registered`.
class AttendanceBucket {
  final String label;
  final double rate; // 0–1
  final int attended;
  final int selected;

  const AttendanceBucket({
    required this.label,
    required this.rate,
    required this.attended,
    required this.selected,
  });

  factory AttendanceBucket.fromJson(Map<String, dynamic> j) {
    final series = (j['series'] as List?) ?? const [];
    final all = series.isNotEmpty && series.first is Map
        ? Map<String, dynamic>.from(series.first as Map)
        : const <String, dynamic>{};
    return AttendanceBucket(
      label: j['label'] as String? ?? '',
      rate: (all['value'] as num?)?.toDouble() ?? 0,
      attended: (all['attended'] as num?)?.toInt() ?? 0,
      selected: (all['selected'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceStat {
  final String stat;
  final String role;
  final String grouping;
  final List<AttendanceBucket> buckets;
  final int registered;
  final int selectedTotal;
  final int attendedTotal;
  final double rate;

  const AttendanceStat({
    required this.stat,
    required this.role,
    required this.grouping,
    required this.buckets,
    required this.registered,
    required this.selectedTotal,
    required this.attendedTotal,
    required this.rate,
  });

  factory AttendanceStat.fromJson(Map<String, dynamic> j) {
    final totals = (j['totals'] as Map?) ?? const {};
    return AttendanceStat(
      stat: j['stat'] as String? ?? 'attendance',
      role: j['role'] as String? ?? '',
      grouping: j['grouping'] as String? ?? 'none',
      buckets: ((j['buckets'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => AttendanceBucket.fromJson(e.cast<String, dynamic>()))
          .toList(),
      registered: (totals['registered'] as num?)?.toInt() ?? 0,
      selectedTotal: (totals['selected'] as num?)?.toInt() ?? 0,
      attendedTotal: (totals['attended'] as num?)?.toInt() ?? 0,
      rate: (totals['rate'] as num?)?.toDouble() ?? 0,
    );
  }
}
