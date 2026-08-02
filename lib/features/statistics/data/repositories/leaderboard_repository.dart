import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/token_storage.dart';
import '../models/leaderboard_models.dart';

/// Read-only access to the V2 §3 leaderboards (top-10). §1.5 adds the same
/// filter set as own statistics (date range + positions|frameworks), except
/// for `metric=points`, which stays unfiltered.
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
    LeaderboardFilter filter = const LeaderboardFilter(),
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
        // §1.5 — points is an all-time Elo rating; the endpoint 422s any
        // filter on it, so nothing is ever sent for that metric.
        if (metric != LeaderboardMetric.points)
          ...filter.toQuery(scope: scope),
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
