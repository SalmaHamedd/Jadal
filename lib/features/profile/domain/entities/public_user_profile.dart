import 'achievement.dart';

/// `GET /users/{id}` (sprinkles §6.1) — another user's public profile. Email,
/// phone and birthDate are only populated when the caller is viewing their
/// own profile or is an admin (backend hides them otherwise); build UI
/// assuming they may be absent.
class PublicUserProfile {
  final int id;
  final String name;
  final String role;
  final String status;
  final String? avatarUrl;
  final int points;
  final int? age;
  final String? location;
  final DateTime createdAt;
  final List<Achievement> topAchievements;
  final String? email;
  final String? phone;
  final String? birthDate;

  const PublicUserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.avatarUrl,
    required this.points,
    this.age,
    this.location,
    required this.createdAt,
    this.topAchievements = const [],
    this.email,
    this.phone,
    this.birthDate,
  });

  /// Tenure in the debate field — derived purely from account creation since
  /// backend confirmed no dedicated "started debating" field exists.
  Duration get tenure => DateTime.now().difference(createdAt);

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) => PublicUserProfile(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        status: json['status'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        points: (json['points'] as num?)?.toInt() ?? 0,
        age: (json['age'] as num?)?.toInt(),
        location: json['location'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        topAchievements: Achievement.listFromJson(json['top_achievements'] as List?),
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        birthDate: json['birth_date'] as String?,
      );
}
