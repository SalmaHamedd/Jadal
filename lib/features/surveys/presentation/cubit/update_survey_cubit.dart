import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question_input.dart';
import 'package:jadal_app/features/surveys/domain/repositories/survey_repository.dart';

part 'update_survey_state.dart';

class UpdateSurveyCubit extends Cubit<UpdateSurveyState> {
  final SurveyRepository _repository;

  UpdateSurveyCubit(this._repository) : super(UpdateSurveyInitial());

  Future<void> submit({
    required int id,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? closesAt,
    bool clearClosesAt = false,
    List<String>? targetRoles,
    List<SurveyQuestionInput>? questions,
  }) async {
    emit(UpdateSurveySubmitting());
    final result = await (_repository as dynamic).updateSurvey(
      id: id,
      title: title,
      description: description,
      clearDescription: clearDescription,
      closesAt: closesAt,
      clearClosesAt: clearClosesAt,
      targetRoles: targetRoles,
      questions: questions,
    );
    result.fold(
      (failure) => emit(UpdateSurveyError(failure.message)),
      (details) => emit(UpdateSurveySuccess(details)),
    );
  }
}
