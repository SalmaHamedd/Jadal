part of 'create_team_cubit.dart';

abstract class CreateTeamState extends Equatable {
  const CreateTeamState();
}

class CreateTeamInitial extends CreateTeamState {
  @override
  List<Object?> get props => [];
}

class CreateTeamSubmitting extends CreateTeamState {
  @override
  List<Object?> get props => [];
}

class CreateTeamSuccess extends CreateTeamState {
  final Team team;
  const CreateTeamSuccess(this.team);
  @override
  List<Object?> get props => [team];
}

class CreateTeamError extends CreateTeamState {
  final String message;
  const CreateTeamError(this.message);
  @override
  List<Object?> get props => [message];
}
