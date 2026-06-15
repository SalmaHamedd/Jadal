import 'package:jadal_app/features/blog/domain/entities/author.dart';

class AuthorModel extends Author {
  const AuthorModel({
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
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      avatarUrl: json['avatar_url'],
      phone: json['phone'],
      points: json['points'],
      lang: json['lang'],
      theme: json['theme'],
      emailVerifiedAt: json['email_verified_at'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}