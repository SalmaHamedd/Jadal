import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../models/activity_stat_model.dart';
import '../models/debater_stats_models.dart';

/// Read-only access to the Debater Statistics API. `debaterId` is the debater's
/// user id; the viewer must be the debater, their coach, or an admin (else 403).
abstract class DebaterStatsRepository {
  Future<Either<Failure, BucketedStat>> getWinRate(int debaterId, StatsFilter filter);

  Future<Either<Failure, BucketedStat>> getAvgScore(int debaterId, StatsFilter filter);

  Future<Either<Failure, BucketedStat>> getBestSpeaker(int debaterId, StatsFilter filter);

  Future<Either<Failure, ScoreRanking>> getScoreRanking(
    int debaterId,
    StatsFilter filter, {
    required RankingMode mode,
    int limit,
  });

  Future<Either<Failure, ImprovementStat>> getImprovement(int debaterId, StatsFilter filter);

  /// V2 §7 — raw weighted activity points + breakdown. Only from/to/group_by
  /// apply; the other filter dimensions have no meaning for this stat.
  /// [role] picks the endpoint family — activity exists for every role
  /// (debater | trainer | judge), unlike the five debater-only stats (§1.9).
  Future<Either<Failure, ActivityStat>> getActivity(int debaterId, StatsFilter filter,
      {String role = 'debater'});
}
