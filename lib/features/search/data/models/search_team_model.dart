import 'package:jadal_app/features/search/domain/entities/search_team.dart';

class TrainerModel extends Trainer {
  const TrainerModel({required super.id, required super.name, super.avatarUrl});

  factory TrainerModel.fromJson(Map<String, dynamic> json) {
    return TrainerModel(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
    );
  }
}

class SearchTeamModel extends SearchTeam {
  const SearchTeamModel({
    required super.id,
    required super.name,
    super.logoUrl,
    required super.membersCount,
    required super.trainer,
    required super.createdAt,
  });

  factory SearchTeamModel.fromJson(Map<String, dynamic> json) {
    return SearchTeamModel(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
      membersCount: json['members_count'],
      trainer: TrainerModel.fromJson(json['trainer']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}