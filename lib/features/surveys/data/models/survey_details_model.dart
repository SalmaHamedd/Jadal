import 'package:jadal_app/features/surveys/data/models/survey_creator_model.dart';
import 'package:jadal_app/features/surveys/data/models/survey_question_model.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';

class SurveyDetailsModel extends SurveyDetails {
  const SurveyDetailsModel({
    required super.id,
    required super.title,
    required super.description,
    required super.targetRoles,
    required super.closesAt,
    required super.isClosed,
    required super.createdBy,
    required super.alreadyResponded,
    required super.createdAt,
    required super.questions,
  });

  factory SurveyDetailsModel.fromJson(Map<String, dynamic> json) {
    return SurveyDetailsModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetRoles: (json['target_roles'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      closesAt: DateTime.parse(json['closes_at']),
      isClosed: json['is_closed'] ?? false,
      createdBy: SurveyCreatorModel.fromJson(json['created_by'] ?? {}),
      alreadyResponded: json['already_responded'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      questions: (json['questions'] as List? ?? [])
          .map((q) => SurveyQuestionModel.fromJson(q))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
    );
  }
}
