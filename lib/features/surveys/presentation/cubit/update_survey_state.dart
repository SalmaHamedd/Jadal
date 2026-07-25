part of 'update_survey_cubit.dart';

abstract class UpdateSurveyState extends Equatable {
  const UpdateSurveyState();
}

class UpdateSurveyInitial extends UpdateSurveyState {
  @override
  List<Object> get props => [];
}

class UpdateSurveySubmitting extends UpdateSurveyState {
  @override
  List<Object> get props => [];
}

class UpdateSurveySuccess extends UpdateSurveyState {
  final SurveyDetails details;
  const UpdateSurveySuccess(this.details);
  @override
  List<Object> get props => [details];
}

class UpdateSurveyError extends UpdateSurveyState {
  final String message;
  const UpdateSurveyError(this.message);
  @override
  List<Object> get props => [message];
}
