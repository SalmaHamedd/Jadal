import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member.dart';

/// A team, as returned by `GET /api/teams` (and the create/mutate endpoints,
/// which all echo back the full updated team).
class Team {
  final int id;
  final String name;
  final String status;
  final bool isRandom;
  final int membersCount;
  final PublicUserProfile? leader;
  final PublicUserProfile? createdBy;
  final List<TeamMember> members;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Team({
    required this.id,
    required this.name,
    required this.status,
    this.isRandom = false,
    required this.membersCount,
    this.leader,
    this.createdBy,
    this.members = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';

  // Kept for TeamPickerField, which only needs names/ids and predates the
  // full leader/createdBy objects.
  String? get leaderName => leader?.name;
  int? get createdById => createdBy?.id;
  String? get createdByName => createdBy?.name;
}
