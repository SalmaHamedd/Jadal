class Trainer {
  final int id;
  final String name;
  final String? avatarUrl;

  const Trainer({required this.id, required this.name, this.avatarUrl});
}

class SearchTeam {
  final int id;
  final String name;
  final String? logoUrl;
  final int membersCount;
  final Trainer trainer;
  final DateTime createdAt;

  const SearchTeam({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.membersCount,
    required this.trainer,
    required this.createdAt,
  });
}