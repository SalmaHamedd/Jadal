import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';

/// A debater's request to join a team — the response of `POST
/// /teams/{id}/join` (always includes `user`, unlike the leave endpoint's
/// self-submission) and each row of `GET /teams/{id}/join-requests`.
class TeamJoinRequest {
  final int id;
  final int teamId;
  final String status;
  final String? reason;
  final DateTime? requestedAt;
  final DateTime? respondedAt;
  final PublicUserProfile? user;

  const TeamJoinRequest({
    required this.id,
    required this.teamId,
    required this.status,
    this.reason,
    this.requestedAt,
    this.respondedAt,
    this.user,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}
