part of 'team_join_cubit.dart';

abstract class TeamJoinState extends Equatable {
  const TeamJoinState();
}

class TeamJoinInitial extends TeamJoinState {
  @override
  List<Object?> get props => [];
}

class TeamJoinSubmitting extends TeamJoinState {
  @override
  List<Object?> get props => [];
}

class TeamJoinSuccess extends TeamJoinState {
  final TeamJoinRequest request;
  const TeamJoinSuccess(this.request);
  @override
  List<Object?> get props => [request];
}

class TeamJoinError extends TeamJoinState {
  final String message;
  const TeamJoinError(this.message);
  @override
  List<Object?> get props => [message];
}
