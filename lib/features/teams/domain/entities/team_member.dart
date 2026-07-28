import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';

/// One row of a team's roster — the membership record (priority/status/
/// joined date) plus the member's public profile.
class TeamMember {
  final int id;
  final int userId;
  final int priority;
  final String status;
  final DateTime? joinedAt;
  final PublicUserProfile user;

  const TeamMember({
    required this.id,
    required this.userId,
    required this.priority,
    required this.status,
    this.joinedAt,
    required this.user,
  });

  bool get isCurrent => status == 'current';
}
