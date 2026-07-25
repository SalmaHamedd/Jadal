part of 'update_trainer_survey_cubit.dart';

abstract class UpdateTrainerSurveyState extends Equatable {
  const UpdateTrainerSurveyState();
}

class UpdateTrainerSurveyInitial extends UpdateTrainerSurveyState {
  @override
  List<Object> get props => [];
}

class UpdateTrainerSurveySubmitting extends UpdateTrainerSurveyState {
  @override
  List<Object> get props => [];
}

class UpdateTrainerSurveySuccess extends UpdateTrainerSurveyState {
  final SurveyDetails details;
  const UpdateTrainerSurveySuccess(this.details);
  @override
  List<Object> get props => [details];
}

class UpdateTrainerSurveyError extends UpdateTrainerSurveyState {
  final String message;
  const UpdateTrainerSurveyError(this.message);
  @override
  List<Object> get props => [message];
}
