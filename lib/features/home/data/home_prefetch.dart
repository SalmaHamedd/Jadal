import 'package:fpdart/fpdart.dart';

import '../../../core/error/failures.dart';
import '../../../di/injection_container.dart' as di;
import '../../blog/data/repositories/blog_repository_impl.dart';
import '../../blog/domain/entities/blog.dart';
import '../../live_debate/data/models/debate_list_model.dart';
import '../../live_debate/data/repositories/live_debate_repository.dart';
import '../../profile/data/repositories/profile_repository.dart';
import '../../profile/domain/entities/profile.dart';
import '../../statistics/data/models/leaderboard_models.dart';
import '../../statistics/data/repositories/leaderboard_repository.dart';

/// Fires the home screen's data requests while the splash timer is
/// still running, so the first post-splash frame renders content instead of a
/// wall of spinners.
/// Every slot is take-once: the first consumer receives the in-flight future
/// (or its already-settled result), the slot is cleared, and any later reload
/// goes to the network exactly as before. Errors travel inside the futures'
/// `Either` results just like a live call, so consumer behaviour is unchanged.
class HomePrefetch {
  HomePrefetch._();

  static Future<Either<Failure, DebateListPage>>? _live;
  static Future<Either<Failure, DebateListPage>>? _scheduled;
  static Future<Either<Failure, DebateListPage>>? _completed;
  static Future<Either<Failure, Leaderboard>>? _leaderboard;
  static Future<Either<Failure, List<Blog>>>? _blogs;
  static Future<Either<Failure, Profile>>? _profile;

  /// Kicks every request without awaiting any of them. Call only when a
  /// session token exists — unauthenticated calls would just 401.
  static void start() {
    final debates = di.sl<LiveDebateRepository>();
    _live = debates.getDebates(status: 'live', perPage: 1);
    _scheduled = debates.getDebates(status: 'scheduled', perPage: 1);
    _completed = debates.getDebates(status: 'completed', perPage: 1);
    _leaderboard = di.sl<LeaderboardRepository>().getLeaderboard(
          LeaderboardScope.debaters,
          LeaderboardMetric.points,
        );
    _blogs = BlogRepositoryImpl().getBlogs();
    _profile = di.sl<ProfileRepository>().getProfile();
  }

  static Future<Either<Failure, DebateListPage>>? takeLive() {
    final f = _live;
    _live = null;
    return f;
  }

  static Future<Either<Failure, DebateListPage>>? takeScheduled() {
    final f = _scheduled;
    _scheduled = null;
    return f;
  }

  static Future<Either<Failure, DebateListPage>>? takeCompleted() {
    final f = _completed;
    _completed = null;
    return f;
  }

  static Future<Either<Failure, Leaderboard>>? takeLeaderboard() {
    final f = _leaderboard;
    _leaderboard = null;
    return f;
  }

  static Future<Either<Failure, List<Blog>>>? takeBlogs() {
    final f = _blogs;
    _blogs = null;
    return f;
  }

  static Future<Either<Failure, Profile>>? takeProfile() {
    final f = _profile;
    _profile = null;
    return f;
  }
}
