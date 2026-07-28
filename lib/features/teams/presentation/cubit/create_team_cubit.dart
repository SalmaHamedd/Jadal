import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';

part 'create_team_state.dart';

class CreateTeamCubit extends Cubit<CreateTeamState> {
  final TeamRepository repository;

  CreateTeamCubit(this.repository) : super(CreateTeamInitial());

  Future<void> submit({
    required String name,
    required int leaderId,
    required List<int> memberIds,
  }) async {
    emit(CreateTeamSubmitting());
    final result = await repository.createTeam(
      name: name,
      leaderId: leaderId,
      memberIds: memberIds,
    );
    result.fold(
      (failure) => emit(CreateTeamError(failure.message)),
      (team) => emit(CreateTeamSuccess(team)),
    );
  }
}
