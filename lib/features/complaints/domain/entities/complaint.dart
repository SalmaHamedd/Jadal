/// A complaint filed by the caller about a debate (optionally targeting a
/// specific user/role in it) — `POST /complaints` and `GET /complaints/mine`.
class Complaint {
  final int id;
  final int debateId;
  final int? targetUserId;
  final String? targetRole;
  final String description;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Complaint({
    required this.id,
    required this.debateId,
    this.targetUserId,
    this.targetRole,
    required this.description,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == 'open';
  bool get isResolved => status == 'resolved';
}
