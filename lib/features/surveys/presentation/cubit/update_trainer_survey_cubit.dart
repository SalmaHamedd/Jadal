import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question_input.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';

part 'update_trainer_survey_state.dart';

class UpdateTrainerSurveyCubit extends Cubit<UpdateTrainerSurveyState> {
  final TrainerSurveyRepository _repository;

  UpdateTrainerSurveyCubit(this._repository) : super(UpdateTrainerSurveyInitial());

  Future<void> submit({
    required int id,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? closesAt,
    bool clearClosesAt = false,
    List<int>? teamIds,
    List<SurveyQuestionInput>? questions,
  }) async {
    emit(UpdateTrainerSurveySubmitting());
    final result = await _repository.updateTrainerSurvey(
      id: id,
      title: title,
      description: description,
      clearDescription: clearDescription,
      closesAt: closesAt,
      clearClosesAt: clearClosesAt,
      teamIds: teamIds,
      questions: questions,
    );
    result.fold(
      (failure) => emit(UpdateTrainerSurveyError(failure.message)),
      (details) => emit(UpdateTrainerSurveySuccess(details)),
    );
  }
}
