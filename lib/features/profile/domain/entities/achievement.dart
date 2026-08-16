/// Rank ordering matches the backend's sort: gold → silver → bronze →
/// honorable → participation (highest first). Wire value is `honorable`
/// — `honoring` no longer exists).
enum AchievementRank { gold, silver, bronze, honorable, participation }

AchievementRank achievementRankFromWire(String? wire) {
  switch (wire) {
    case 'gold':
      return AchievementRank.gold;
    case 'silver':
      return AchievementRank.silver;
    case 'bronze':
      return AchievementRank.bronze;
    case 'honorable':
      return AchievementRank.honorable;
    default:
      return AchievementRank.participation;
  }
}

class Achievement {
  final int id;
  final int userId;
  final String name;
  final AchievementRank rank;
  final String? imageUrl;
  final DateTime? awardedAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.name,
    required this.rank,
    this.imageUrl,
    this.awardedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: (json['user_id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        rank: achievementRankFromWire(json['rank'] as String?),
        imageUrl: json['image_url'] as String?,
        awardedAt: (json['assigned_at'] ?? json['awarded_at']) != null
            ? DateTime.tryParse((json['assigned_at'] ?? json['awarded_at']) as String)
            : null,
      );

  static List<Achievement> listFromJson(List<dynamic>? raw) =>
      (raw ?? const []).whereType<Map>().map((e) => Achievement.fromJson(e.cast<String, dynamic>())).toList();
}
