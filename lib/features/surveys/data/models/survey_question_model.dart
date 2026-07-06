import 'package:jadal_app/features/surveys/domain/entities/survey_question.dart';

class SurveyQuestionModel extends SurveyQuestion {
  const SurveyQuestionModel({
    required super.id,
    required super.questionText,
    required super.type,
    required super.options,
    required super.orderIndex,
  });

  factory SurveyQuestionModel.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionModel(
      id: json['id'],
      questionText: json['question_text'] ?? '',
      type: json['type'] ?? 'open_text',
      options: json['options'],
      orderIndex: json['order_index'] ?? 0,
    );
  }
}
