import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/function/json_utils.dart';
import '../../../../core/services/token_storage.dart';
import '../models/debater_stats_models.dart';
import 'debater_stats_repository.dart';

/// HTTP implementation. Matches the app's repository convention: `http.Client` +
/// `TokenStorage` bearer + `Accept: application/json` + `Either<Failure, T>`,
/// decoding the `{success,message,data}` envelope and mapping error codes per
/// the spec (403 forbidden viewer · 422 bad filter · 404 unknown debater).
class DebaterStatsRepositoryImpl implements DebaterStatsRepository {
  final http.Client _client;

  DebaterStatsRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GETs [url] with [query], returning the decoded `data` object or a [Failure].
  Future<Either<Failure, Map<String, dynamic>>> _getData(
    String url,
    Map<String, String> query,
  ) async {
    final uri = Uri.parse(url).replace(queryParameters: query.isEmpty ? null : query);
    try {
      final res = await _client.get(uri, headers: await _headers());
      Map<String, dynamic>? body;
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      }
      final code = res.statusCode;
      if (code >= 200 && code < 300) {
        final data = asMap(body?['data']);
        if (data == null) return const Left(ServerFailure('Unexpected empty response'));
        return Right(data);
      }
      final message = asString(body?['message']);
      switch (code) {
        case 401:
          await TokenStorage.deleteToken();
          return Left(AuthFailure(message ?? 'Unauthenticated'));
        case 403:
          return Left(ForbiddenFailure(message ?? 'Not allowed to view these stats'));
        case 404:
          return Left(NotFoundFailure(message ?? 'Debater not found'));
        case 422:
          return Left(ValidationFailure(message ?? 'Invalid filter'));
        case 429:
          return Left(RateLimitFailure(message ?? 'Too many requests'));
        default:
          return Left(ServerFailure(message ?? 'Server error ($code)'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, BucketedStat>> getWinRate(int debaterId, StatsFilter filter) async =>
      (await _getData(ApiConstants.winRateUrl(debaterId), filter.toQuery()))
          .map(BucketedStat.fromJson);

  @override
  Future<Either<Failure, BucketedStat>> getAvgScore(int debaterId, StatsFilter filter) async =>
      (await _getData(ApiConstants.avgScoreUrl(debaterId), filter.toQuery()))
          .map(BucketedStat.fromJson);

  @override
  Future<Either<Failure, BucketedStat>> getBestSpeaker(int debaterId, StatsFilter filter) async =>
      (await _getData(ApiConstants.bestSpeakerUrl(debaterId), filter.toQuery()))
          .map(BucketedStat.fromJson);

  @override
  Future<Either<Failure, ScoreRanking>> getScoreRanking(
    int debaterId,
    StatsFilter filter, {
    required RankingMode mode,
    int limit = 5,
  }) async {
    // Ranking ignores group_by/series; adds ranking_mode + limit.
    final query = {
      ...filter.toQuery(includeGrouping: false),
      'ranking_mode': mode.wire,
      'limit': limit.toString(),
    };
    return (await _getData(ApiConstants.scoreRankingUrl(debaterId), query))
        .map(ScoreRanking.fromJson);
  }

  @override
  Future<Either<Failure, ImprovementStat>> getImprovement(
      int debaterId, StatsFilter filter) async =>
      (await _getData(
        ApiConstants.improvementUrl(debaterId),
        filter.toQuery(includeGrouping: false),
      ))
          .map(ImprovementStat.fromJson);
}
