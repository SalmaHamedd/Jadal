part of 'trainer_survey_results_cubit.dart';

abstract class TrainerSurveyResultsState extends Equatable {
  const TrainerSurveyResultsState();
}

class TrainerSurveyResultsInitial extends TrainerSurveyResultsState {
  @override
  List<Object> get props => [];
}

class TrainerSurveyResultsLoading extends TrainerSurveyResultsState {
  @override
  List<Object> get props => [];
}

class TrainerSurveyResultsLoaded extends TrainerSurveyResultsState {
  final SurveyResults results;
  const TrainerSurveyResultsLoaded(this.results);
  @override
  List<Object> get props => [results];
}

class TrainerSurveyResultsError extends TrainerSurveyResultsState {
  final String message;
  const TrainerSurveyResultsError(this.message);
  @override
  List<Object> get props => [message];
}
