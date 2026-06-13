import 'package:jadal_app/features/search/domain/entities/search_user.dart';

class SearchUserModel extends SearchUser {
  const SearchUserModel({
    required super.id,
    required super.name,
    required super.role,
    super.avatarUrl,
    required super.points,
    required super.createdAt,
  });

  factory SearchUserModel.fromJson(Map<String, dynamic> json) {
    return SearchUserModel(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
      points: json['points'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}