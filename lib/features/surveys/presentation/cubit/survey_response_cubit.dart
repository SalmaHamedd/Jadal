import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/repositories/survey_repository.dart';

part 'survey_response_state.dart';

class SurveyResponseCubit extends Cubit<SurveyResponseState> {
  final SurveyRepository _repository;

  SurveyResponseCubit(this._repository) : super(SurveyResponseInitial());

  Future<void> submitResponse({
    required int surveyId,
    required Map<String, dynamic> answers,
  }) async {
    emit(SurveyResponseSubmitting());
    final result = await _repository.submitSurveyResponse(
      surveyId: surveyId,
      answers: answers,
    );
    result.fold(
      (failure) => emit(SurveyResponseError(failure.message)),
      (_) => emit(SurveyResponseSuccess()),
    );
  }
}
