import 'package:jadal_app/features/teams/domain/entities/team.dart';

class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.name,
    required super.status,
    required super.membersCount,
    super.leaderName,
    super.createdById,
    super.createdByName,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final leader = json['leader'] as Map<String, dynamic>?;
    final createdBy = json['created_by'] as Map<String, dynamic>?;
    return TeamModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      membersCount: (json['members_count'] as num?)?.toInt() ??
          (json['members'] as List?)?.length ??
          0,
      leaderName: leader?['name'],
      createdById: createdBy?['id'],
      createdByName: createdBy?['name'],
    );
  }
}
