import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/entities/team_join_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_leave_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member_priority.dart';

abstract class TeamRepository {
  /// For a trainer: the teams they created. For a debater: active,
  /// non-random teams they're not currently a member of (a "find a team to
  /// join" view) — [search] filters by name in that case.
  Future<Either<Failure, List<Team>>> getTeams({String? search});

  Future<Either<Failure, Team>> createTeam({
    required String name,
    required int leaderId,
    required List<int> memberIds,
  });

  Future<Either<Failure, void>> deactivateTeam(int teamId);

  Future<Either<Failure, Team>> addMembers({
    required int teamId,
    required List<int> memberIds,
  });

  Future<Either<Failure, void>> removeMember({
    required int teamId,
    required int userId,
  });

  Future<Either<Failure, Team>> updateMembersPriority({
    required int teamId,
    required List<TeamMemberPriority> members,
  });

  Future<Either<Failure, TeamLeaveRequest>> leaveTeam({
    required int teamId,
    String? reason,
  });

  Future<Either<Failure, List<TeamLeaveRequest>>> getLeaveRequests(int teamId);

  Future<Either<Failure, TeamLeaveRequest>> respondToLeaveRequest({
    required int teamId,
    required int requestId,
    required bool accept,
  });

  Future<Either<Failure, TeamJoinRequest>> joinTeam({
    required int teamId,
    String? reason,
  });

  Future<Either<Failure, List<TeamJoinRequest>>> getJoinRequests(int teamId);

  Future<Either<Failure, TeamJoinRequest>> respondToJoinRequest({
    required int teamId,
    required int requestId,
    required bool accept,
  });
}
