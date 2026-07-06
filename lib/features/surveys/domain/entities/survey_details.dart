import 'package:jadal_app/features/surveys/domain/entities/survey.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question.dart';

/// A survey as returned by `GET /api/surveys/{id}` — includes questions.
class SurveyDetails extends Survey {
  final List<SurveyQuestion> questions;

  const SurveyDetails({
    required super.id,
    required super.title,
    required super.description,
    required super.targetRoles,
    required super.closesAt,
    required super.isClosed,
    required super.createdBy,
    required super.alreadyResponded,
    required super.createdAt,
    required this.questions,
  });
}
