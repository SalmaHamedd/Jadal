import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member.dart';

class TeamMemberModel extends TeamMember {
  const TeamMemberModel({
    required super.id,
    required super.userId,
    required super.priority,
    required super.status,
    super.joinedAt,
    required super.user,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return TeamMemberModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'current',
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? ''),
      user: userJson != null
          ? PublicUserProfile.fromJson(userJson)
          : PublicUserProfile(
              id: (json['user_id'] as num?)?.toInt() ?? 0,
              name: '',
              role: '',
              status: 'active',
              points: 0,
              createdAt: DateTime.now(),
            ),
    );
  }
}
