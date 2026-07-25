import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';

part 'delete_trainer_survey_state.dart';

class DeleteTrainerSurveyCubit extends Cubit<DeleteTrainerSurveyState> {
  final TrainerSurveyRepository _repository;

  DeleteTrainerSurveyCubit(this._repository) : super(DeleteTrainerSurveyInitial());

  Future<void> deleteSurvey(int id) async {
    emit(DeleteTrainerSurveyDeleting());
    final result = await _repository.deleteTrainerSurvey(id);
    result.fold(
      (failure) => emit(DeleteTrainerSurveyError(failure.message)),
      (_) => emit(DeleteTrainerSurveySuccess()),
    );
  }
}
