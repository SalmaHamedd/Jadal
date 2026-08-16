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
      // copyWith, NOT a fresh TeamDetailState: constructing a new
      // state resets `joinRequests`/`leaveRequests` to their `const []` default,
      // which wiped the pending-request sections off the screen after any
      // successful mutation.
      (team) => emit(state.copyWith(busy: false, team: team)),
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

  /// Reorders the roster. The new order is applied **optimistically** so the
  /// list settles where the finger dropped it instead of snapping back to the
  /// old order until the server echoes the team; a failure rolls it back.
  Future<void> updatePriorities(List<TeamMemberPriority> members) async {
    final previous = state.team;
    final order = {for (final m in members) m.userId: m.priority};
    final reordered = [...state.team.members]
      ..sort((a, b) => (order[a.userId] ?? a.priority)
          .compareTo(order[b.userId] ?? b.priority));
    emit(state.copyWith(
      busy: true,
      clearError: true,
      team: _teamWithMembers([
        for (var i = 0; i < reordered.length; i++)
          reordered[i].copyWith(priority: i + 1),
      ]),
    ));

    final result = await repository.updateMembersPriority(
      teamId: previous.id,
      members: members,
    );
    result.fold(
      // Roll back to the pre-drag order — leaving the optimistic order on
      // screen after a failed write would misreport the saved state.
      (failure) => emit(state.copyWith(
        busy: false,
        error: failure.message,
        team: previous,
      )),
      // copyWith, NOT a fresh TeamDetailState (see addMembers).
      (team) => emit(state.copyWith(busy: false, team: team)),
    );
  }

  Team _teamWithMembers(List<TeamMember> members) => Team(
        id: state.team.id,
        name: state.team.name,
        status: state.team.status,
        isRandom: state.team.isRandom,
        membersCount: state.team.membersCount,
        leader: state.team.leader,
        createdBy: state.team.createdBy,
        members: members,
        createdAt: state.team.createdAt,
        updatedAt: state.team.updatedAt,
      );

  Future<void> deactivate() async {
    emit(state.copyWith(busy: true, clearError: true));
    final result = await repository.deactivateTeam(state.team.id);
    result.fold(
      (failure) => emit(state.copyWith(busy: false, error: failure.message)),
      (_) => emit(state.copyWith(busy: false, deactivated: true)),
    );
  }
}
