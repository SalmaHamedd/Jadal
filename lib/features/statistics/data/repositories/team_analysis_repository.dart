import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/session_guard.dart';
import '../../../../core/services/token_storage.dart';
import '../models/activity_stat_model.dart';
import '../models/debater_stats_models.dart';
import '../models/judge_rating_model.dart';
import '../models/team_analysis_models.dart';

/// MF_FU §3–§5 — the round's new read-only analytics.
///
/// The per-team metric endpoints return the **debater envelopes verbatim**
/// (same keys, same `grouping` values, same `label` formats), so
/// [BucketedStat] / [ImprovementStat] / [ActivityStat] are reused unchanged
/// rather than duplicated for teams.
class TeamAnalysisRepository {
  final http.Client _client;
  TeamAnalysisRepository({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Either<Failure, dynamic>> _getData(
    String url,
    Map<String, String> query,
  ) async {
    try {
      final uri = Uri.parse(url).replace(
        queryParameters: query.isEmpty ? null : query,
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
        if (data == null) {
          return const Left(ServerFailure('Unexpected empty response'));
        }
        return Right(data);
      }
      final message = body?['message'] as String?;
      if (res.statusCode == 401) {
        // Rejected token: clear the session and return to login, instead of
        // leaving the user in an app where every request fails.
        SessionGuard.onUnauthorized();
        return Left(AuthFailure(message ?? 'Unauthenticated'));
      }
      return switch (res.statusCode) {
        403 => Left(ForbiddenFailure(message ?? 'Forbidden')),
        404 => Left(NotFoundFailure(message ?? 'Not found')),
        422 => Left(ServerFailure(message ?? 'Invalid request')),
        _ => Left(ServerFailure(message ?? 'Server error (${res.statusCode})')),
      };
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  // ── §3.1b — the coach's teams, for the picker ──────────────────────────────
  Future<Either<Failure, List<TrainerTeam>>> getTrainerTeams(
    int trainerId,
  ) async {
    final res = await _getData(ApiConstants.trainerTeamsUrl(trainerId), const {});
    return res.map((data) {
      final list = data is List ? data : const [];
      return [
        for (final e in list)
          if (e is Map) TrainerTeam.fromJson(e.cast<String, dynamic>()),
      ];
    });
  }

  // ── §3.2 — per-team metrics, reusing the debater shapes ────────────────────
  Future<Either<Failure, BucketedStat>> getTeamBucketed(
    int teamId,
    String metric, // 'win-rate' | 'avg-score'
    StatsFilter filter,
  ) async =>
      (await _getData(
        ApiConstants.teamStatUrl(teamId, metric),
        filter.toQuery(),
      ))
          .map((d) => BucketedStat.fromJson((d as Map).cast<String, dynamic>()));

  Future<Either<Failure, ImprovementStat>> getTeamImprovement(
    int teamId,
    StatsFilter filter,
  ) async =>
      (await _getData(
        ApiConstants.teamStatUrl(teamId, 'improvement'),
        filter.toQuery(includeGrouping: false),
      ))
          .map(
            (d) => ImprovementStat.fromJson((d as Map).cast<String, dynamic>()),
          );

  /// Team activity is the **sum over the team's current members**, so it scales
  /// with squad size — a 10-person team out-scores an equally engaged 4-person
  /// one. The caller divides by `members_counted` (returned alongside) to get
  /// the comparable per-member figure; raw values must not be compared across
  /// teams of different sizes.
  Future<Either<Failure, ({ActivityStat stat, int membersCounted})>>
      getTeamActivity(int teamId, StatsFilter filter) async {
    final query = {
      if (filter.from != null) 'from': filter.from!,
      if (filter.to != null) 'to': filter.to!,
      'group_by': filter.groupBy.wire,
    };
    return (await _getData(
      ApiConstants.teamStatUrl(teamId, 'activity'),
      query,
    ))
        .map((d) {
      final map = (d as Map).cast<String, dynamic>();
      return (
        stat: ActivityStat.fromJson(map),
        membersCounted: (map['members_counted'] as num?)?.toInt() ?? 0,
      );
    });
  }

  // ── §4 — line-up (combination) analysis ────────────────────────────────────
  Future<Either<Failure, TeamCombinationsStat>> getTeamCombinations(
    int teamId, {
    String? from,
    String? to,
    List<int> frameworks = const [],
    CombinationMetric metric = CombinationMetric.winRate,
    int minDebates = 2,
    int limit = 10,
  }) async {
    final query = <String, String>{
      'from': ?from,
      'to': ?to,
      if (frameworks.isNotEmpty) 'frameworks': frameworks.join(','),
      'metric': metric.wire,
      'min_debates': '$minDebates',
      'limit': '$limit',
    };
    return (await _getData(
      ApiConstants.teamCombinationsUrl(teamId),
      query,
    ))
        .map(
          (d) =>
              TeamCombinationsStat.fromJson((d as Map).cast<String, dynamic>()),
        );
  }

  // ── §5 — judge ratings received ────────────────────────────────────────────
  Future<Either<Failure, JudgeRatingStat>> getJudgeRatings(
    int judgeId, {
    String? from,
    String? to,
    StatsGroupBy groupBy = StatsGroupBy.none,
    List<int> frameworks = const [],
  }) async {
    final query = <String, String>{
      'from': ?from,
      'to': ?to,
      'group_by': groupBy.wire,
      if (frameworks.isNotEmpty) 'frameworks': frameworks.join(','),
    };
    return (await _getData(ApiConstants.judgeRatingsUrl(judgeId), query))
        .map((d) => JudgeRatingStat.fromJson((d as Map).cast<String, dynamic>()));
  }
}
