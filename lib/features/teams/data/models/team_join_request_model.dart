import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';
import 'package:jadal_app/features/teams/domain/entities/team_join_request.dart';

class TeamJoinRequestModel extends TeamJoinRequest {
  const TeamJoinRequestModel({
    required super.id,
    required super.teamId,
    required super.status,
    super.reason,
    super.requestedAt,
    super.respondedAt,
    super.user,
  });

  factory TeamJoinRequestModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return TeamJoinRequestModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      teamId: (json['team_id'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      reason: json['reason'] as String?,
      requestedAt: DateTime.tryParse(json['requested_at'] as String? ?? ''),
      respondedAt: DateTime.tryParse(json['responded_at'] as String? ?? ''),
      user: userJson != null ? PublicUserProfile.fromJson(userJson) : null,
    );
  }
}
