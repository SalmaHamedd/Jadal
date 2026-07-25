import 'package:jadal_app/features/surveys/domain/entities/survey_results.dart';

class SurveyRespondentModel extends SurveyRespondent {
  const SurveyRespondentModel({super.id, required super.name, super.avatarUrl, super.role});

  factory SurveyRespondentModel.fromJson(Map<String, dynamic> json) {
    return SurveyRespondentModel(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] ?? 'مستخدم').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class SurveyIndividualResponseModel extends SurveyIndividualResponse {
  const SurveyIndividualResponseModel({
    super.id,
    required super.respondent,
    required super.answers,
    super.submittedAt,
  });

  factory SurveyIndividualResponseModel.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'] as Map<String, dynamic>?;
    final respondent = userRaw != null
        ? SurveyRespondentModel.fromJson(userRaw)
        : const SurveyRespondentModel(name: 'مستخدم غير معروف');

    final answersRaw = json['answers'];
    final answers = (answersRaw is Map)
        ? answersRaw.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    final tsRaw = json['submitted_at'];
    final submittedAt = (tsRaw is String) ? DateTime.tryParse(tsRaw) : null;

    return SurveyIndividualResponseModel(
      id: (json['id'] as num?)?.toInt(),
      respondent: respondent,
      answers: answers,
      submittedAt: submittedAt,
    );
  }
}

class SurveyResultsQuestionModel extends SurveyResultsQuestion {
  const SurveyResultsQuestionModel({
    required super.id,
    required super.questionText,
    required super.type,
    required super.options,
    super.average,
    super.distribution,
    super.textAnswers,
    super.totalAnswered,
  });

  factory SurveyResultsQuestionModel.fromJson(Map<String, dynamic> json) {
    final aggregate = json['aggregate'] as Map<String, dynamic>?;

    double? average;
    Map<String, int>? distribution;
    List<String>? textAnswers;
    int? total;

    if (aggregate != null) {
      final avgRaw = aggregate['average'];
      if (avgRaw is num) average = avgRaw.toDouble();

      final distRaw = aggregate['distribution'];
      if (distRaw is Map) {
        distribution = distRaw.map(
          (k, v) => MapEntry(k.toString(), v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0),
        );
      }

      final answersRaw = aggregate['answers'];
      if (answersRaw is List) {
        textAnswers = answersRaw.map((e) => e.toString()).toList();
      }

      final totalRaw = aggregate['total'];
      if (totalRaw is num) total = totalRaw.toInt();
    }

    return SurveyResultsQuestionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      questionText: (json['question_text'] ?? '').toString(),
      type: (json['type'] ?? 'open_text').toString(),
      options: json['options'],
      average: average,
      distribution: distribution,
      textAnswers: textAnswers,
      totalAnswered: total,
    );
  }
}

class SurveyResultsModel extends SurveyResults {
  const SurveyResultsModel({
    required super.surveyId,
    super.title,
    super.description,
    super.totalResponses,
    super.questions,
    super.responses,
    required super.raw,
  });

  factory SurveyResultsModel.fromJson(int surveyId, Map<String, dynamic> json) {
    final questionsRaw = json['questions'];
    final questions = (questionsRaw is List)
        ? questionsRaw
            .whereType<Map<String, dynamic>>()
            .map(SurveyResultsQuestionModel.fromJson)
            .toList()
        : <SurveyResultsQuestionModel>[];

    final responsesRaw = json['responses'];
    final responses = (responsesRaw is List)
        ? responsesRaw
            .whereType<Map<String, dynamic>>()
            .map(SurveyIndividualResponseModel.fromJson)
            .toList()
        : <SurveyIndividualResponseModel>[];

    final totalRaw = json['total_responses'];
    final totalResponses = (totalRaw is num) ? totalRaw.toInt() : responses.length;

    return SurveyResultsModel(
      surveyId: (json['id'] as num?)?.toInt() ?? surveyId,
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      totalResponses: totalResponses,
      questions: questions,
      responses: responses,
      raw: json,
    );
  }
}
