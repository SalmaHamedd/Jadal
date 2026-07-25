part of 'create_trainer_survey_cubit.dart';

abstract class CreateTrainerSurveyState extends Equatable {
  const CreateTrainerSurveyState();
}

class CreateTrainerSurveyInitial extends CreateTrainerSurveyState {
  @override
  List<Object> get props => [];
}

class CreateTrainerSurveySubmitting extends CreateTrainerSurveyState {
  @override
  List<Object> get props => [];
}

class CreateTrainerSurveySuccess extends CreateTrainerSurveyState {
  final Survey survey;
  const CreateTrainerSurveySuccess(this.survey);
  @override
  List<Object> get props => [survey];
}

/// The survey itself was created successfully, but the follow-up call to
/// attach its questions failed. Since surveys can't be edited afterward,
/// this leaves a permanently question-less (unusable) survey — the UI
/// should tell the trainer plainly rather than treat this as a clean success.
class CreateTrainerSurveyPartialSuccess extends CreateTrainerSurveyState {
  final Survey survey;
  final String message;
  const CreateTrainerSurveyPartialSuccess(this.survey, this.message);
  @override
  List<Object> get props => [survey, message];
}

class CreateTrainerSurveyError extends CreateTrainerSurveyState {
  final String message;
  const CreateTrainerSurveyError(this.message);
  @override
  List<Object> get props => [message];
}
