/// Results for a survey, from `GET /trainer/surveys/{id}/results`: the
/// questions with their aggregates, plus every individual response.

/// The person who submitted a response.
class SurveyRespondent {
  final int? id;
  final String name;
  final String? avatarUrl;
  final String? role;

  const SurveyRespondent({this.id, required this.name, this.avatarUrl, this.role});
}

/// One person's full submission: who they are + their answer to every
/// question, keyed by question id (as a string).
class SurveyIndividualResponse {
  final int? id;
  final SurveyRespondent respondent;
  final Map<String, dynamic> answers;
  final DateTime? submittedAt;

  const SurveyIndividualResponse({
    this.id,
    required this.respondent,
    required this.answers,
    this.submittedAt,
  });
}

/// One question's server-computed aggregate, plus enough of the question
/// itself (text/type/options) to render it without needing a separate fetch.
class SurveyResultsQuestion {
  final int id;
  final String questionText;

  /// 'rating' | 'mcq' | 'open_text'
  final String type;
  final dynamic options;

  /// `aggregate.average` — rating questions.
  final double? average;

  /// `aggregate.distribution` — mcq questions (option → count).
  final Map<String, int>? distribution;

  /// `aggregate.answers` — open_text questions.
  final List<String>? textAnswers;

  /// `aggregate.total` — how many people answered this specific question.
  final int? totalAnswered;

  const SurveyResultsQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.options,
    this.average,
    this.distribution,
    this.textAnswers,
    this.totalAnswered,
  });

  bool get isRating => type == 'rating';
  bool get isMcq => type == 'mcq';
  bool get isOpenText => type == 'open_text';

  int get ratingMax => (options is Map) ? (options['max'] as num?)?.toInt() ?? 5 : 5;
}

class SurveyResults {
  final int surveyId;
  final String? title;
  final String? description;
  final int? totalResponses;
  final List<SurveyResultsQuestion> questions;
  final List<SurveyIndividualResponse> responses;
  final Map<String, dynamic> raw;

  const SurveyResults({
    required this.surveyId,
    this.title,
    this.description,
    this.totalResponses,
    this.questions = const [],
    this.responses = const [],
    required this.raw,
  });
}
