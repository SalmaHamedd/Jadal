part of 'survey_details_cubit.dart';

abstract class SurveyDetailsState extends Equatable {
  const SurveyDetailsState();
}

class SurveyDetailsInitial extends SurveyDetailsState {
  @override
  List<Object> get props => [];
}

class SurveyDetailsLoading extends SurveyDetailsState {
  @override
  List<Object> get props => [];
}

class SurveyDetailsLoaded extends SurveyDetailsState {
  final SurveyDetails details;
  const SurveyDetailsLoaded(this.details);
  @override
  List<Object> get props => [details];
}

class SurveyDetailsError extends SurveyDetailsState {
  final String message;
  const SurveyDetailsError(this.message);
  @override
  List<Object> get props => [message];
}
