import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';

part 'team_state.dart';

class TeamCubit extends Cubit<TeamState> {
  final TeamRepository repository;

  TeamCubit(this.repository) : super(TeamInitial());

  Future<void> loadTeams() async {
    emit(TeamLoading());
    final result = await repository.getTeams();
    result.fold(
      (failure) => emit(TeamError(failure.message)),
      (teams) => emit(TeamLoaded(teams)),
    );
  }
}
