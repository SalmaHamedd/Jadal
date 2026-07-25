part of 'trainer_survey_details_cubit.dart';

abstract class TrainerSurveyDetailsState extends Equatable {
  const TrainerSurveyDetailsState();
}

class TrainerSurveyDetailsInitial extends TrainerSurveyDetailsState {
  @override
  List<Object> get props => [];
}

class TrainerSurveyDetailsLoading extends TrainerSurveyDetailsState {
  @override
  List<Object> get props => [];
}

class TrainerSurveyDetailsLoaded extends TrainerSurveyDetailsState {
  final SurveyDetails details;
  const TrainerSurveyDetailsLoaded(this.details);
  @override
  List<Object> get props => [details];
}

class TrainerSurveyDetailsError extends TrainerSurveyDetailsState {
  final String message;
  const TrainerSurveyDetailsError(this.message);
  @override
  List<Object> get props => [message];
}
