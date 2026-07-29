import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/teams/domain/entities/team_join_request.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';

part 'team_join_state.dart';

class TeamJoinCubit extends Cubit<TeamJoinState> {
  final TeamRepository repository;

  TeamJoinCubit(this.repository) : super(TeamJoinInitial());

  Future<void> join(int teamId, {String? reason}) async {
    emit(TeamJoinSubmitting());
    final result = await repository.joinTeam(teamId: teamId, reason: reason);
    result.fold(
      (failure) => emit(TeamJoinError(failure.message)),
      (request) => emit(TeamJoinSuccess(request)),
    );
  }
}
