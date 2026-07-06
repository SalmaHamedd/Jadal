import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';

abstract class SurveyRepository {
  Future<Either<Failure, List<Survey>>> getSurveys({
    int page = 1,
    int perPage = 15,
  });

  Future<Either<Failure, SurveyDetails>> getSurveyDetails(int id);

  /// [answers] maps `question_id` (as string) → the answer value
  /// (num for rating, String for mcq/open_text).
  Future<Either<Failure, void>> submitSurveyResponse({
    required int surveyId,
    required Map<String, dynamic> answers,
  });
}
