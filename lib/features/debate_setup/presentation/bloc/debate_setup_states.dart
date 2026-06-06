abstract class DebateSetupStates {}

class DebateSetupInitialState extends DebateSetupStates {}

class DebateSetupChangeTeamAssignmentState extends DebateSetupStates {}

class DebateSetupGetAllTopicsLoadingState extends DebateSetupStates {}

class DebateSetupGetAllTopicsSuccessState extends DebateSetupStates {}

class DebateSetupGetAllTopicsErrorState extends DebateSetupStates {
  final String message;

  DebateSetupGetAllTopicsErrorState({required this.message});
}

class DebateSetupGetAllMotionsLoadingState extends DebateSetupStates {}

class DebateSetupGetAllMotionsSuccessState extends DebateSetupStates {}

class DebateSetupGetAllMotionsErrorState extends DebateSetupStates {
  final String message;

  DebateSetupGetAllMotionsErrorState({required this.message});
}

class DebateSetupMotionsFilteredState extends DebateSetupStates {}

class DebateSetupChangeTopicState extends DebateSetupStates {}

class DebateSetupAddTopicToNewMotionState extends DebateSetupStates {}

class DebateSetupMotionSelectState extends DebateSetupStates {}