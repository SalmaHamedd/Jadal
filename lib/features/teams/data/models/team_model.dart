import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';
import 'package:jadal_app/features/teams/data/models/team_member_model.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';

class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.name,
    required super.status,
    super.isRandom,
    required super.membersCount,
    super.leader,
    super.createdBy,
    super.members,
    super.createdAt,
    super.updatedAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final leaderJson = json['leader'] as Map<String, dynamic>?;
    final createdByJson = json['created_by'] as Map<String, dynamic>?;
    // `current_members` is the server's canonical "who's active now" view;
    // `members` includes historical rows too, so prefer the former when present.
    final membersJson = (json['current_members'] as List?) ?? (json['members'] as List?) ?? [];
    final members = membersJson
        .whereType<Map>()
        .map((e) => TeamMemberModel.fromJson(e.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return TeamModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      isRandom: json['is_random'] == true || json['is_random'] == 1,
      membersCount: (json['members_count'] as num?)?.toInt() ?? members.length,
      leader: leaderJson != null ? PublicUserProfile.fromJson(leaderJson) : null,
      createdBy: createdByJson != null ? PublicUserProfile.fromJson(createdByJson) : null,
      members: members,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}
