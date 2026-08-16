class Profile {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? avatarUrl;
  final String? phone;
  final int points;
  final String? lang;
  final String? theme;
  final String? emailVerifiedAt;
  final String createdAt;
  // Backend stores birthDate, computes+returns age; location
  // is a plain editable string. All three ride on GET/PUT /profile now.
  final int? age;
  final String? location;
  final String? birthDate;

  const Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.phone,
    required this.points,
    this.lang,
    this.theme,
    this.emailVerifiedAt,
    required this.createdAt,
    this.age,
    this.location,
    this.birthDate,
  });
}