import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_results.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';

part 'trainer_survey_results_state.dart';

class TrainerSurveyResultsCubit extends Cubit<TrainerSurveyResultsState> {
  final TrainerSurveyRepository _repository;

  TrainerSurveyResultsCubit(this._repository) : super(TrainerSurveyResultsInitial());

  Future<void> loadResults(int surveyId) async {
    emit(TrainerSurveyResultsLoading());
    final result = await _repository.getTrainerSurveyResults(surveyId);
    result.fold(
      (failure) => emit(TrainerSurveyResultsError(failure.message)),
      (results) => emit(TrainerSurveyResultsLoaded(results)),
    );
  }
}
