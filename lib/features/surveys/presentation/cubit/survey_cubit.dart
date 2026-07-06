import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey.dart';
import 'package:jadal_app/features/surveys/domain/repositories/survey_repository.dart';

part 'survey_state.dart';

class SurveyCubit extends Cubit<SurveyState> {
  final SurveyRepository repository;

  SurveyCubit(this.repository) : super(SurveyInitial());

  Future<void> loadSurveys() async {
    emit(SurveyLoading());
    final result = await repository.getSurveys();
    result.fold(
      (failure) => emit(SurveyError(failure.message)),
      (surveys) => emit(SurveyLoaded(surveys)),
    );
  }
}
