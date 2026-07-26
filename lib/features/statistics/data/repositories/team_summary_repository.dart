import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/token_storage.dart';
import '../models/team_summary_model.dart';

/// Read-only access to `GET /trainers/{id}/stats/team-summary` (V2 §3).
/// Same auth policy as the other stats endpoints: self, admin, or public
/// unless the target opted out via stats_visible.
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

  Future<Either<Failure, TeamSummaryStat>> getTeamSummary(int trainerId) async {
    try {
      final uri = Uri.parse(ApiConstants.trainerTeamSummaryUrl(trainerId));
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
