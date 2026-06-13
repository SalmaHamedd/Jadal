class SearchUser {
  final int id;
  final String name;
  final String role;
  final String? avatarUrl;
  final int points;
  final DateTime createdAt;

  const SearchUser({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.points,
    required this.createdAt,
  });
}