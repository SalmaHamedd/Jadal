import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
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
}
