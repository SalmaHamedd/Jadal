import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/entities/team_join_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_leave_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member_priority.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';

part 'team_detail_state.dart';

/// Owns one team's mutations (add/remove members, reorder priority,
/// deactivate). Starts from the [Team] the caller already has (from the
/// list) and keeps it in sync locally using the full team object every
/// mutation endpoint echoes back — `GET /teams/{id}` exists but isn't
/// needed here since every write already returns the updated team.
class TeamDetailCubit extends Cubit<TeamDetailState> {
  final TeamRepository repository;

  TeamDetailCubit(this.repository, Team initial)
      : super(TeamDetailState(team: initial));

  Future<void> addMembers(List<int> memberIds) async {
    emit(state.copyWith(busy: true, clearError: true));
    final result = await repository.addMembers(teamId: state.team.id, memberIds: memberIds);
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (team) => emit(TeamDetailState(team: team)),
    );
  }

  Future<void> removeMember(int userId) async {
    emit(state.copyWith(busy: true, clearError: true));
    final result = await repository.removeMember(teamId: state.team.id, userId: userId);
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (_) => emit(state.copyWith(busy: false, team: _teamWithoutMember(userId))),
    );
  }

  Team _teamWithoutMember(int userId) => Team(
        id: state.team.id,
        name: state.team.name,
        status: state.team.status,
        isRandom: state.team.isRandom,
        membersCount: state.team.membersCount - 1,
        leader: state.team.leader,
        createdBy: state.team.createdBy,
        members: state.team.members.where((m) => m.userId != userId).toList(),
        createdAt: state.team.createdAt,
        updatedAt: state.team.updatedAt,
      );

  Future<void> loadLeaveRequests() async {
    emit(state.copyWith(loadingLeaveRequests: true));
    final result = await repository.getLeaveRequests(state.team.id);
    result.fold(
      (failure) => emit(state.copyWith(loadingLeaveRequests: false, error: failure.message)),
      (requests) => emit(state.copyWith(
        loadingLeaveRequests: false,
        leaveRequests: requests.where((r) => r.isPending).toList(),
      )),
    );
  }

  Future<void> respondToLeaveRequest(int requestId, {required bool accept}) async {
    emit(state.copyWith(busy: true, clearError: true));
    final result = await repository.respondToLeaveRequest(
      teamId: state.team.id,
      requestId: requestId,
      accept: accept,
    );
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (responded) {
        final remaining = state.leaveRequests.where((r) => r.id != requestId).toList();
        emit(state.copyWith(
          busy: false,
          leaveRequests: remaining,
          team: (accept && responded.user != null)
              ? _teamWithoutMember(responded.user!.id)
              : state.team,
        ));
      },
    );
  }

  Team _teamWithMemberAdded(TeamMember member) => Team(
        id: state.team.id,
        name: state.team.name,
        status: state.team.status,
        isRandom: state.team.isRandom,
        membersCount: state.team.membersCount + 1,
        leader: state.team.leader,
        createdBy: state.team.createdBy,
        members: [...state.team.members, member],
        createdAt: state.team.createdAt,
        updatedAt: state.team.updatedAt,
      );

  Future<void> loadJoinRequests() async {
    emit(state.copyWith(loadingJoinRequests: true));
    final result = await repository.getJoinRequests(state.team.id);
    result.fold(
      (failure) => emit(state.copyWith(loadingJoinRequests: false, error: failure.message)),
      (requests) => emit(state.copyWith(
        loadingJoinRequests: false,
        joinRequests: requests.where((r) => r.isPending).toList(),
      )),
    );
  }

  Future<void> respondToJoinRequest(int requestId, {required bool accept}) async {
    emit(state.copyWith(busy: true, clearError: true));
    final result = await repository.respondToJoinRequest(
      teamId: state.team.id,
      requestId: requestId,
      accept: accept,
    );
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (responded) {
        final remaining = state.joinRequests.where((r) => r.id != requestId).toList();
        final user = responded.user;
        final alreadyMember = user != null &&
            state.team.members.any((m) => m.userId == user.id);
        final team = (accept && user != null && !alreadyMember)
            ? _teamWithMemberAdded(TeamMember(
                id: -responded.id,
                userId: user.id,
                priority: state.team.members.length + 1,
                status: 'current',
                joinedAt: DateTime.now(),
                user: user,
              ))
            : state.team;
        emit(state.copyWith(busy: false, joinRequests: remaining, team: team));
      },
    );
  }

  Future<void> updatePriorities(List<TeamMemberPriority> members) async {
    emit(state.copyWith(busy: true, clearError: true));
    final result = await repository.updateMembersPriority(
      teamId: state.team.id,
      members: members,
    );
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (team) => emit(TeamDetailState(team: team)),
    );
  }

  Future<void> deactivate() async {
    emit(state.copyWith(busy: true, clearError: true));
    final result = await repository.deactivateTeam(state.team.id);
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (_) => emit(state.copyWith(busy: false, deactivated: true)),
    );
  }
}
