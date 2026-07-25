import 'package:jadal_app/features/surveys/domain/entities/survey_question.dart';

/// A question definition used when replacing a survey's question list via
/// `PUT /admin/surveys/{id}` or `PUT /trainer/surveys/{id}`.
///
/// This is intentionally separate from [SurveyQuestion] (the read-model
/// returned by the API) since the write shape differs: `options` depends on
/// `type`, and `order_index` is optional there.
class SurveyQuestionInput {
  final String questionText;

  /// 'rating' | 'mcq' | 'open_text'
  final String type;

  final int ratingMin;
  final int ratingMax;
  final int ratingStep;
  final List<String> mcqOptions;

  /// 0-based position. Always sent explicitly (rather than relying on the
  /// backend's auto-assignment) so ordering is unambiguous.
  final int orderIndex;

  const SurveyQuestionInput({
    required this.questionText,
    required this.type,
    this.ratingMin = 1,
    this.ratingMax = 10,
    this.ratingStep = 1,
    this.mcqOptions = const [],
    required this.orderIndex,
  });

  /// Seeds an editable draft from an existing (read-model) question, so an
  /// edit form can start from the survey's current questions.
  factory SurveyQuestionInput.fromExisting(SurveyQuestion q) {
    return SurveyQuestionInput(
      questionText: q.questionText,
      type: q.type,
      ratingMin: q.ratingMin,
      ratingMax: q.ratingMax,
      ratingStep: q.ratingStep,
      mcqOptions: q.mcqOptions,
      orderIndex: q.orderIndex,
    );
  }

  SurveyQuestionInput copyWith({
    String? questionText,
    String? type,
    int? ratingMin,
    int? ratingMax,
    int? ratingStep,
    List<String>? mcqOptions,
    int? orderIndex,
  }) {
    return SurveyQuestionInput(
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      ratingMin: ratingMin ?? this.ratingMin,
      ratingMax: ratingMax ?? this.ratingMax,
      ratingStep: ratingStep ?? this.ratingStep,
      mcqOptions: mcqOptions ?? this.mcqOptions,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  /// Trims the question text and drops blank option rows (editor UI allows
  /// empty option fields mid-edit; those must not leak into the request).
  SurveyQuestionInput get cleaned => copyWith(
        questionText: questionText.trim(),
        mcqOptions: mcqOptions.map((o) => o.trim()).where((o) => o.isNotEmpty).toList(),
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'question_text': questionText,
      'type': type,
      'order_index': orderIndex,
    };
    if (type == 'rating') {
      map['options'] = {'min': ratingMin, 'max': ratingMax, 'step': ratingStep};
    } else if (type == 'mcq') {
      map['options'] = mcqOptions;
    }
    // open_text: no `options` key at all.
    return map;
  }
}
