part of 'team_cubit.dart';

abstract class TeamState extends Equatable {
  const TeamState();
}

class TeamInitial extends TeamState {
  @override
  List<Object> get props => [];
}

class TeamLoading extends TeamState {
  @override
  List<Object> get props => [];
}

class TeamLoaded extends TeamState {
  final List<Team> teams;
  const TeamLoaded(this.teams);
  @override
  List<Object> get props => [teams];
}

class TeamError extends TeamState {
  final String message;
  const TeamError(this.message);
  @override
  List<Object> get props => [message];
}
