import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/leaderboard_models.dart';
import '../../data/repositories/leaderboard_repository.dart';

enum LeaderboardStatus { loading, ready, error }

class LeaderboardState {
  final LeaderboardScope scope;
  final LeaderboardMetric metric;
  final LeaderboardStatus status;
  final Leaderboard? board;
  final String? error;

  const LeaderboardState({
    required this.scope,
    required this.metric,
    required this.status,
    this.board,
    this.error,
  });

  LeaderboardState copyWith({
    LeaderboardScope? scope,
    LeaderboardMetric? metric,
    LeaderboardStatus? status,
    Leaderboard? board,
    String? error,
  }) =>
      LeaderboardState(
        scope: scope ?? this.scope,
        metric: metric ?? this.metric,
        status: status ?? this.status,
        board: board ?? this.board,
        error: error,
      );
}

/// Drives the public-statistics screen: one (scope, metric) pair visible at a
/// time, with already-fetched boards cached so flipping between tabs/chips is
/// instant instead of refetching top-10s that just loaded.
class LeaderboardCubit extends Cubit<LeaderboardState> {
  final LeaderboardRepository repo;
  final _cache = <(LeaderboardScope, LeaderboardMetric), Leaderboard>{};

  LeaderboardCubit({required this.repo})
      : super(const LeaderboardState(
          scope: LeaderboardScope.debaters,
          metric: LeaderboardMetric.points,
          status: LeaderboardStatus.loading,
        ));

  Future<void> load() => _fetch(state.scope, state.metric);

  void setScope(LeaderboardScope scope) {
    if (scope == state.scope) return;
    // best_speaker doesn't exist for teams — snap back to points.
    final metric = state.metric.availableFor(scope) ? state.metric : LeaderboardMetric.points;
    _fetch(scope, metric);
  }

  void setMetric(LeaderboardMetric metric) {
    if (metric == state.metric || !metric.availableFor(state.scope)) return;
    _fetch(state.scope, metric);
  }

  Future<void> _fetch(LeaderboardScope scope, LeaderboardMetric metric) async {
    final cached = _cache[(scope, metric)];
    if (cached != null) {
      emit(state.copyWith(
          scope: scope, metric: metric, status: LeaderboardStatus.ready, board: cached));
      return;
    }
    emit(state.copyWith(scope: scope, metric: metric, status: LeaderboardStatus.loading));
    final res = await repo.getLeaderboard(scope, metric);
    if (isClosed) return;
    // Ignore a stale response if the user already switched away.
    if (scope != state.scope || metric != state.metric) return;
    res.fold(
      (f) => emit(state.copyWith(status: LeaderboardStatus.error, error: f.message)),
      (board) {
        _cache[(scope, metric)] = board;
        emit(state.copyWith(status: LeaderboardStatus.ready, board: board));
      },
    );
  }
}
