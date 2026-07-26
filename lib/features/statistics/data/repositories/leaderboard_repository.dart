import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/token_storage.dart';
import '../models/leaderboard_models.dart';

/// Read-only access to the V2 §3 leaderboards. All-time, top-10, no date
/// filter (per contract); opted-out users are already excluded server-side.
class LeaderboardRepository {
  final http.Client _client;
  LeaderboardRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Either<Failure, Leaderboard>> getLeaderboard(
    LeaderboardScope scope,
    LeaderboardMetric metric, {
    int limit = 10,
  }) async {
    if (!metric.availableFor(scope)) {
      return const Left(ServerFailure('Metric not available for teams'));
    }
    try {
      final base = scope == LeaderboardScope.debaters
          ? ApiConstants.leaderboardDebatersUrl
          : ApiConstants.leaderboardTeamsUrl;
      final uri = Uri.parse(base).replace(queryParameters: {
        'metric': metric.wire,
        'limit': '$limit',
      });
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
        return Right(Leaderboard.fromJson(data.cast<String, dynamic>(), scope, metric));
      }
      final message = body?['message'] as String?;
      return Left(ServerFailure(message ?? 'Server error (${res.statusCode})'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
