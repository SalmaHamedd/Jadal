import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/features/teams/data/models/team_join_request_model.dart';
import 'package:jadal_app/features/teams/data/models/team_leave_request_model.dart';
import 'package:jadal_app/features/teams/data/models/team_model.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/entities/team_join_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_leave_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member_priority.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';

class TeamRepositoryImpl implements TeamRepository {
  final http.Client client;

  TeamRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  Future<String?> _token() => PreferencesDatabase().getToken();

  Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Failure _failureFor(int statusCode, Map<String, dynamic> json, String fallback) {
    switch (statusCode) {
      case 401:
        return AuthFailure(json['message'] ?? 'Unauthenticated');
      case 403:
        return ForbiddenFailure(json['message'] ?? 'Unauthorized');
      case 404:
        return NotFoundFailure(json['message'] ?? 'Team not found');
      case 422:
        final errorsRaw = json['errors'];
        Map<String, List<String>>? errors;
        if (errorsRaw is Map) {
          errors = errorsRaw.map(
            (key, value) => MapEntry(
              key.toString(),
              (value as List).map((e) => e.toString()).toList(),
            ),
          );
        }
        return ValidationFailure(json['message'] ?? 'Validation error', errors: errors);
      default:
        return ServerFailure(json['message'] ?? fallback);
    }
  }

  @override
  Future<Either<Failure, List<Team>>> getTeams({String? search}) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final uri = Uri.parse(ApiConstants.teamsUrl).replace(
        queryParameters: (search != null && search.isNotEmpty) ? {'search': search} : null,
      );
      final response = await client.get(uri, headers: await _headers());

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        final teams = data.map((item) => TeamModel.fromJson(item)).toList();
        return Right(teams);
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to load teams'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Team>> createTeam({
    required String name,
    required int leaderId,
    required List<int> memberIds,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.post(
        Uri.parse(ApiConstants.teamsUrl),
        headers: await _headers(),
        body: jsonEncode({
          'name': name,
          'leader_id': leaderId,
          'members': memberIds,
        }),
      );

      final json = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          json['success'] == true) {
        return Right(TeamModel.fromJson(json['data'] ?? {}));
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to create team'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateTeam(int teamId) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.delete(
        Uri.parse(ApiConstants.teamUrl(teamId)),
        headers: await _headers(),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return const Right(null);
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to deactivate team'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Team>> addMembers({
    required int teamId,
    required List<int> memberIds,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.post(
        Uri.parse(ApiConstants.teamMembersUrl(teamId)),
        headers: await _headers(),
        body: jsonEncode({'member_ids': memberIds}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return Right(TeamModel.fromJson(json['data'] ?? {}));
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to add members'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeMember({
    required int teamId,
    required int userId,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.delete(
        Uri.parse(ApiConstants.teamMemberUrl(teamId, userId)),
        headers: await _headers(),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return const Right(null);
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to remove member'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Team>> updateMembersPriority({
    required int teamId,
    required List<TeamMemberPriority> members,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.put(
        Uri.parse(ApiConstants.teamMembersPriorityUrl(teamId)),
        headers: await _headers(),
        body: jsonEncode({'members': members.map((m) => m.toJson()).toList()}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return Right(TeamModel.fromJson(json['data'] ?? {}));
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to reorder members'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, TeamLeaveRequest>> leaveTeam({
    required int teamId,
    String? reason,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.post(
        Uri.parse(ApiConstants.teamLeaveUrl(teamId)),
        headers: await _headers(),
        body: jsonEncode({if (reason != null && reason.isNotEmpty) 'reason': reason}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return Right(TeamLeaveRequestModel.fromJson(json['data'] ?? {}));
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to submit leave request'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TeamLeaveRequest>>> getLeaveRequests(int teamId) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.teamLeaveRequestsUrl(teamId)),
        headers: await _headers(),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        return Right(data.map((item) => TeamLeaveRequestModel.fromJson(item)).toList());
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to load leave requests'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, TeamLeaveRequest>> respondToLeaveRequest({
    required int teamId,
    required int requestId,
    required bool accept,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.patch(
        Uri.parse(ApiConstants.teamLeaveRequestRespondUrl(teamId, requestId)),
        headers: await _headers(),
        body: jsonEncode({'status': accept ? 'accepted' : 'rejected'}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return Right(TeamLeaveRequestModel.fromJson(json['data'] ?? {}));
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to respond to leave request'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, TeamJoinRequest>> joinTeam({
    required int teamId,
    String? reason,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.post(
        Uri.parse(ApiConstants.teamJoinUrl(teamId)),
        headers: await _headers(),
        body: jsonEncode({if (reason != null && reason.isNotEmpty) 'reason': reason}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return Right(TeamJoinRequestModel.fromJson(json['data'] ?? {}));
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to submit join request'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TeamJoinRequest>>> getJoinRequests(int teamId) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.teamJoinRequestsUrl(teamId)),
        headers: await _headers(),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        return Right(data.map((item) => TeamJoinRequestModel.fromJson(item)).toList());
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to load join requests'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, TeamJoinRequest>> respondToJoinRequest({
    required int teamId,
    required int requestId,
    required bool accept,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.patch(
        Uri.parse(ApiConstants.teamJoinRequestRespondUrl(teamId, requestId)),
        headers: await _headers(),
        body: jsonEncode({'status': accept ? 'accepted' : 'rejected'}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return Right(TeamJoinRequestModel.fromJson(json['data'] ?? {}));
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to respond to join request'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
