import 'package:jadal_app/features/surveys/domain/entities/survey_creator.dart';

class SurveyCreatorModel extends SurveyCreator {
  const SurveyCreatorModel({
    required super.id,
    required super.name,
    super.email,
    super.role,
    super.avatarUrl,
  });

  factory SurveyCreatorModel.fromJson(Map<String, dynamic> json) {
    return SurveyCreatorModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
    );
  }
}
