part of 'team_leave_cubit.dart';

abstract class TeamLeaveState extends Equatable {
  const TeamLeaveState();
}

class TeamLeaveInitial extends TeamLeaveState {
  @override
  List<Object?> get props => [];
}

class TeamLeaveSubmitting extends TeamLeaveState {
  @override
  List<Object?> get props => [];
}

class TeamLeaveSuccess extends TeamLeaveState {
  final TeamLeaveRequest request;
  const TeamLeaveSuccess(this.request);
  @override
  List<Object?> get props => [request];
}

class TeamLeaveError extends TeamLeaveState {
  final String message;
  const TeamLeaveError(this.message);
  @override
  List<Object?> get props => [message];
}
