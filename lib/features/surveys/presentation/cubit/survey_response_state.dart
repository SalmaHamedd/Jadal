part of 'survey_response_cubit.dart';

abstract class SurveyResponseState extends Equatable {
  const SurveyResponseState();
}

class SurveyResponseInitial extends SurveyResponseState {
  @override
  List<Object> get props => [];
}

class SurveyResponseSubmitting extends SurveyResponseState {
  @override
  List<Object> get props => [];
}

class SurveyResponseSuccess extends SurveyResponseState {
  @override
  List<Object> get props => [];
}

class SurveyResponseError extends SurveyResponseState {
  final String message;
  const SurveyResponseError(this.message);
  @override
  List<Object> get props => [message];
}
