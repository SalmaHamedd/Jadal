import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/token_storage.dart';
import '../models/team_summary_model.dart';

/// Read-only access to `GET /trainers/{id}/stats/team-summary`.
/// Same auth policy as the other stats endpoints: self, admin, or public
///.
class TeamSummaryRepository {
  final http.Client _client;
  TeamSummaryRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Omit [teamId] for the all-teams average (unchanged
  /// behaviour); pass it for that one team, where `teams_counted` becomes 1.
  /// An unknown id and a team this trainer doesn't coach both return 403,
  /// deliberately indistinguishable so the endpoint can't be used to probe
  /// which team ids exist.
  Future<Either<Failure, TeamSummaryStat>> getTeamSummary(
    int trainerId, {
    int? teamId,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConstants.trainerTeamSummaryUrl(trainerId),
      ).replace(
        queryParameters: teamId == null ? null : {'team_id': '$teamId'},
      );
      final res = await _client.get(uri, headers: await _headers());
      Map<String, dynamic>? body;
      if (res.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) body = decoded;
        } catch (_) {/* non-JSON body */}
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = body?['data'];
        if (data is! Map) return const Left(ServerFailure('Unexpected empty response'));
        return Right(TeamSummaryStat.fromJson(data.cast<String, dynamic>()));
      }
      final message = body?['message'] as String?;
      switch (res.statusCode) {
        case 403:
          return Left(ForbiddenFailure(message ?? 'Forbidden'));
        case 404:
          return Left(NotFoundFailure(message ?? 'Not found'));
        default:
          return Left(ServerFailure(message ?? 'Server error (${res.statusCode})'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
