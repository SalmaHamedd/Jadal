import 'package:jadal_app/features/profile/domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.status,
    super.avatarUrl,
    super.phone,
    required super.points,
    super.lang,
    super.theme,
    super.emailVerifiedAt,
    required super.createdAt,
    super.age,
    super.location,
    super.birthDate,
    super.statsVisible,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      avatarUrl: json['avatar_url'],
      phone: json['phone'],
      points: json['points'] ?? 0,
      lang: json['lang'],
      theme: json['theme'],
      emailVerifiedAt: json['email_verified_at'],
      createdAt: json['created_at'],
      age: (json['age'] as num?)?.toInt(),
      location: json['location'],
      birthDate: json['birth_date'],
      statsVisible: json['stats_visible'] is bool ? json['stats_visible'] : true,
    );
  }
}