import 'package:jadal_app/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
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
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'avatar_url': avatarUrl,
      'phone': phone,
      'points': points,
      'lang': lang,
      'theme': theme,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
    };
  }
}