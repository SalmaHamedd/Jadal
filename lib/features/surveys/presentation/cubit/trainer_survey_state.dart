part of 'trainer_survey_cubit.dart';

abstract class TrainerSurveyState extends Equatable {
  const TrainerSurveyState();
}

class TrainerSurveyInitial extends TrainerSurveyState {
  @override
  List<Object> get props => [];
}

class TrainerSurveyLoading extends TrainerSurveyState {
  @override
  List<Object> get props => [];
}

class TrainerSurveyLoaded extends TrainerSurveyState {
  final List<Survey> surveys;
  const TrainerSurveyLoaded(this.surveys);
  @override
  List<Object> get props => [surveys];
}

class TrainerSurveyError extends TrainerSurveyState {
  final String message;
  const TrainerSurveyError(this.message);
  @override
  List<Object> get props => [message];
}
