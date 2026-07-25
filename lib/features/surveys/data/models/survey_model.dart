import 'package:jadal_app/features/surveys/data/models/survey_creator_model.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey.dart';

class SurveyModel extends Survey {
  const SurveyModel({
    required super.id,
    required super.title,
    required super.description,
    required super.targetRoles,
    required super.closesAt,
    required super.isClosed,
    required super.createdBy,
    required super.alreadyResponded,
    required super.createdAt,
  });

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    return SurveyModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetRoles: (json['target_roles'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      closesAt: json['closes_at'] != null ? DateTime.parse(json['closes_at']) : null,
      isClosed: json['is_closed'] ?? false,
      createdBy: SurveyCreatorModel.fromJson(json['created_by'] ?? {}),
      alreadyResponded: json['already_responded'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
