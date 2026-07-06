import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';
import 'package:jadal_app/features/surveys/domain/repositories/survey_repository.dart';

part 'survey_details_state.dart';

class SurveyDetailsCubit extends Cubit<SurveyDetailsState> {
  final SurveyRepository _repository;

  SurveyDetailsCubit(this._repository) : super(SurveyDetailsInitial());

  Future<void> loadSurveyDetails(int id) async {
    emit(SurveyDetailsLoading());
    final result = await _repository.getSurveyDetails(id);
    result.fold(
      (failure) => emit(SurveyDetailsError(failure.message)),
      (details) => emit(SurveyDetailsLoaded(details)),
    );
  }
}
