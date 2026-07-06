part of 'survey_cubit.dart';

abstract class SurveyState extends Equatable {
  const SurveyState();
}

class SurveyInitial extends SurveyState {
  @override
  List<Object> get props => [];
}

class SurveyLoading extends SurveyState {
  @override
  List<Object> get props => [];
}

class SurveyLoaded extends SurveyState {
  final List<Survey> surveys;
  const SurveyLoaded(this.surveys);
  @override
  List<Object> get props => [surveys];
}

class SurveyError extends SurveyState {
  final String message;
  const SurveyError(this.message);
  @override
  List<Object> get props => [message];
}
