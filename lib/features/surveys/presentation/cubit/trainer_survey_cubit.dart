import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';

part 'trainer_survey_state.dart';

class TrainerSurveyCubit extends Cubit<TrainerSurveyState> {
  final TrainerSurveyRepository repository;

  TrainerSurveyCubit(this.repository) : super(TrainerSurveyInitial());

  Future<void> loadSurveys() async {
    emit(TrainerSurveyLoading());
    final result = await repository.getTrainerSurveys();
    result.fold(
      (failure) => emit(TrainerSurveyError(failure.message)),
      (surveys) => emit(TrainerSurveyLoaded(surveys)),
    );
  }
}
