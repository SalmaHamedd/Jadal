import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/teams/domain/entities/team_leave_request.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';

part 'team_leave_state.dart';

class TeamLeaveCubit extends Cubit<TeamLeaveState> {
  final TeamRepository repository;

  TeamLeaveCubit(this.repository) : super(TeamLeaveInitial());

  Future<void> leave(int teamId, {String? reason}) async {
    emit(TeamLeaveSubmitting());
    final result = await repository.leaveTeam(teamId: teamId, reason: reason);
    result.fold(
      (failure) => emit(TeamLeaveError(failure.message)),
      (request) => emit(TeamLeaveSuccess(request)),
    );
  }
}
