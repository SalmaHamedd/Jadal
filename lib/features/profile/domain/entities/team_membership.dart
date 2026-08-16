/// A user's membership on a team, current or past.
/// `leftAt` is null for current memberships.
class TeamMembership {
  final int teamId;
  final String teamName;
  final String role; // "leader" | "member" | "trainer" (wire value unchanged)
  final DateTime? joinedAt;
  final DateTime? leftAt;

  /// Auto-generated per-debate teams (created when a solo debater
  /// is assigned to an ad-hoc side) are not real memberships and must never
  /// appear on a profile. The backend now excludes them from both
  /// `GET /users/{id}/teams` and `/teams/history`, and returns this flag so the
  /// exclusion is verifiable; the UI filters on it as well.
  final bool isRandom;

  const TeamMembership({
    required this.teamId,
    required this.teamName,
    required this.role,
    this.joinedAt,
    this.leftAt,
    this.isRandom = false,
  });

  factory TeamMembership.fromJson(Map<String, dynamic> json) => TeamMembership(
        teamId: (json['team_id'] as num?)?.toInt() ?? 0,
        teamName: json['team_name'] as String? ?? '',
        role: json['role'] as String? ?? 'member',
        joinedAt: json['joined_at'] != null
            ? DateTime.tryParse(json['joined_at'] as String)
            : null,
        leftAt: json['left_at'] != null ? DateTime.tryParse(json['left_at'] as String) : null,
        isRandom: json['is_random'] as bool? ?? false,
      );

  static List<TeamMembership> listFromJson(List<dynamic>? raw) => (raw ?? const [])
      .whereType<Map>()
      .map((e) => TeamMembership.fromJson(e.cast<String, dynamic>()))
      .toList();
}
