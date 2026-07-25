part of 'delete_trainer_survey_cubit.dart';

abstract class DeleteTrainerSurveyState extends Equatable {
  const DeleteTrainerSurveyState();
}

class DeleteTrainerSurveyInitial extends DeleteTrainerSurveyState {
  @override
  List<Object> get props => [];
}

class DeleteTrainerSurveyDeleting extends DeleteTrainerSurveyState {
  @override
  List<Object> get props => [];
}

class DeleteTrainerSurveySuccess extends DeleteTrainerSurveyState {
  @override
  List<Object> get props => [];
}

class DeleteTrainerSurveyError extends DeleteTrainerSurveyState {
  final String message;
  const DeleteTrainerSurveyError(this.message);
  @override
  List<Object> get props => [message];
}
