import 'package:jadal_app/features/surveys/domain/entities/survey_creator.dart';

/// A survey as returned by `GET /api/surveys` (list item — no questions).
class Survey {
  final int id;
  final String title;
  final String description;
  final List<String> targetRoles;
  final DateTime? closesAt;
  final bool isClosed;
  final SurveyCreator createdBy;
  final bool alreadyResponded;
  final DateTime createdAt;

  const Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.targetRoles,
    required this.closesAt,
    required this.isClosed,
    required this.createdBy,
    required this.alreadyResponded,
    required this.createdAt,
  });

  /// Whether the person can still submit a response.
  bool get canRespond => !isClosed && !alreadyResponded;
}
