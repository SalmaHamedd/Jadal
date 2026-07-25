/// A team, as returned by `GET /api/teams`.
///
/// Kept intentionally lean — just enough to show and pick a team (e.g. for
/// the trainer survey team picker). Doesn't model members/leader in full;
/// add fields here if another screen ends up needing them.
class Team {
  final int id;
  final String name;
  final String status;
  final int membersCount;
  final String? leaderName;
  final int? createdById;
  final String? createdByName;

  const Team({
    required this.id,
    required this.name,
    required this.status,
    required this.membersCount,
    this.leaderName,
    this.createdById,
    this.createdByName,
  });

  bool get isActive => status == 'active';
}
