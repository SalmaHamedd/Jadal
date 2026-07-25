import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question_input.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_results.dart';

/// Surveys a trainer created for their own team(s) — a separate scope from
/// the general [SurveyRepository], backed by the `/trainer/surveys` routes.
abstract class TrainerSurveyRepository {
  Future<Either<Failure, List<Survey>>> getTrainerSurveys({
    int page = 1,
    int perPage = 15,
  });

  Future<Either<Failure, SurveyDetails>> getTrainerSurveyDetails(int id);

  /// [teamIds] must all be teams owned by the current trainer.
  Future<Either<Failure, Survey>> createTrainerSurvey({
    required String title,
    String? description,
    required List<int> teamIds,
    DateTime? closesAt,
  });

  Future<Either<Failure, SurveyResults>> getTrainerSurveyResults(int id);

  /// `PUT /trainer/surveys/{id}` — caller must be the survey's creator.
  /// Every parameter is optional and only sent if provided. [teamIds] fully
  /// replaces team assignments if sent (send `[]` to clear all teams).
  /// Use [clearDescription]/[clearClosesAt] to explicitly send `null` for
  /// those two (vs. omitting them entirely).
  Future<Either<Failure, SurveyDetails>> updateTrainerSurvey({
    required int id,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? closesAt,
    bool clearClosesAt = false,
    List<int>? teamIds,
    List<SurveyQuestionInput>? questions,
  });

  /// `DELETE /trainer/surveys/{id}` — caller must be the survey's creator.
  Future<Either<Failure, void>> deleteTrainerSurvey(int id);
}
