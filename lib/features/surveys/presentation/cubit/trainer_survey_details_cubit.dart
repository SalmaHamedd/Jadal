import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';

part 'trainer_survey_details_state.dart';

class TrainerSurveyDetailsCubit extends Cubit<TrainerSurveyDetailsState> {
  final TrainerSurveyRepository _repository;

  TrainerSurveyDetailsCubit(this._repository) : super(TrainerSurveyDetailsInitial());

  Future<void> loadSurveyDetails(int id) async {
    emit(TrainerSurveyDetailsLoading());
    final result = await _repository.getTrainerSurveyDetails(id);
    result.fold(
      (failure) => emit(TrainerSurveyDetailsError(failure.message)),
      (details) => emit(TrainerSurveyDetailsLoaded(details)),
    );
  }
}
