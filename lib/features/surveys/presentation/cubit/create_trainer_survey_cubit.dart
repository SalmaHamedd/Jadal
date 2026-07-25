import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question_input.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';

part 'create_trainer_survey_state.dart';

class CreateTrainerSurveyCubit extends Cubit<CreateTrainerSurveyState> {
  final TrainerSurveyRepository _repository;

  CreateTrainerSurveyCubit(this._repository) : super(CreateTrainerSurveyInitial());

  /// Creates the survey via `POST /trainer/surveys` (which doesn't accept
  /// `questions`), then — if [questions] is non-empty — immediately attaches
  /// them via `PUT /trainer/surveys/{id}` so the whole thing feels like one
  /// step to the trainer.
  Future<void> submit({
    required String title,
    String? description,
    required List<int> teamIds,
    DateTime? closesAt,
    List<SurveyQuestionInput> questions = const [],
  }) async {
    emit(CreateTrainerSurveySubmitting());
    final createResult = await _repository.createTrainerSurvey(
      title: title,
      description: description,
      teamIds: teamIds,
      closesAt: closesAt,
    );

    await createResult.fold(
      (failure) async => emit(CreateTrainerSurveyError(failure.message)),
      (created) async {
        if (questions.isEmpty) {
          emit(CreateTrainerSurveySuccess(created));
          return;
        }
        final updateResult = await _repository.updateTrainerSurvey(
          id: created.id,
          questions: questions,
        );
        updateResult.fold(
          (failure) => emit(CreateTrainerSurveyPartialSuccess(created, failure.message)),
          (withQuestions) => emit(CreateTrainerSurveySuccess(withQuestions)),
        );
      },
    );
  }
}
