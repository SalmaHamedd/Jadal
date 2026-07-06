/// The admin/user who created a survey (the `created_by` object in the API).
class SurveyCreator {
  final int id;
  final String name;
  final String? email;
  final String? role;
  final String? avatarUrl;

  const SurveyCreator({
    required this.id,
    required this.name,
    this.email,
    this.role,
    this.avatarUrl,
  });
}
