import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/entities/team_leave_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member_priority.dart';

abstract class TeamRepository {
  Future<Either<Failure, List<Team>>> getTeams();

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
}
