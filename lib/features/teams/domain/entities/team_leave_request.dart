import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';

/// A member's leave request — the response of `POST /teams/{id}/leave` (the
/// debater's own submission, no `user`) and each row of
/// `GET /teams/{id}/leave-requests` (the trainer's view, `user` populated).
class TeamLeaveRequest {
  final int id;
  final int teamId;
  final String status;
  final String? reason;
  final DateTime? requestedAt;
  final DateTime? respondedAt;
  final PublicUserProfile? user;

  const TeamLeaveRequest({
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
