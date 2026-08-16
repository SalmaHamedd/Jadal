import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/app_models/framework.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/leaderboard_models.dart';
import '../../data/repositories/leaderboard_repository.dart';
import 'debater_stats_cubit.dart' show StatsFilterDim;

enum LeaderboardStatus { loading, ready, error }

class LeaderboardState {
  final LeaderboardScope scope;
  final LeaderboardMetric metric;
  final LeaderboardStatus status;
  final Leaderboard? board;
  final String? error;

  /// The shared filter (ignored by the backend-strip for points).
  final LeaderboardFilter filter;
  final StatsFilterDim dim;
  final List<Framework> frameworkOptions;

  const LeaderboardState({
    required this.scope,
    required this.metric,
    required this.status,
    this.board,
    this.error,
    this.filter = const LeaderboardFilter(),
    this.dim = StatsFilterDim.positions,
    this.frameworkOptions = const [],
  });

  /// / — the Points tab hides every filter control.
  bool get filtersAvailable => metric != LeaderboardMetric.points;

  LeaderboardState copyWith({
    LeaderboardScope? scope,
    LeaderboardMetric? metric,
    LeaderboardStatus? status,
    Leaderboard? board,
    String? error,
    LeaderboardFilter? filter,
    StatsFilterDim? dim,
    List<Framework>? frameworkOptions,
  }) =>
      LeaderboardState(
        scope: scope ?? this.scope,
        metric: metric ?? this.metric,
        status: status ?? this.status,
        board: board ?? this.board,
        error: error,
        filter: filter ?? this.filter,
        dim: dim ?? this.dim,
        frameworkOptions: frameworkOptions ?? this.frameworkOptions,
      );
}

/// Drives the public-statistics screen: one (scope, metric) pair visible at a
/// time, with already-fetched boards cached so flipping between tabs/chips is
/// instant instead of refetching top-10s that just loaded. Any filter change
/// invalidates the cache — cached boards belong to the previous filter.
class LeaderboardCubit extends Cubit<LeaderboardState> {
  final LeaderboardRepository repo;

  /// Loads the framework filter options (`GET /motion-frameworks`).
  final Future<Either<Failure, List<Framework>>> Function()? frameworksLoader;

  final _cache = <(LeaderboardScope, LeaderboardMetric), Leaderboard>{};

  LeaderboardCubit({required this.repo, this.frameworksLoader})
      : super(const LeaderboardState(
          scope: LeaderboardScope.debaters,
          metric: LeaderboardMetric.points,
          status: LeaderboardStatus.loading,
        ));

  Future<void> load() {
    _loadFrameworkOptions();
    return _fetch(state.scope, state.metric);
  }

  Future<void> _loadFrameworkOptions() async {
    if (frameworksLoader == null || state.frameworkOptions.isNotEmpty) return;
    final res = await frameworksLoader!();
    if (isClosed) return;
    res.fold((_) {}, (list) => emit(state.copyWith(frameworkOptions: list)));
  }

  void setScope(LeaderboardScope scope) {
    if (scope == state.scope) return;
    // best_speaker doesn't exist for teams — snap back to points.
    final metric = state.metric.availableFor(scope) ? state.metric : LeaderboardMetric.points;
    // Positions are rejected on the teams leaderboard — drop them and
    // land on the framework dimension there.
    if (scope == LeaderboardScope.teams &&
        (state.dim == StatsFilterDim.positions || state.filter.positions.isNotEmpty)) {
      if (state.filter.positions.isNotEmpty) _cache.clear();
      emit(state.copyWith(
        dim: StatsFilterDim.frameworks,
        filter: state.filter.copyWith(positions: const []),
      ));
    }
    _fetch(scope, metric);
  }

  void setMetric(LeaderboardMetric metric) {
    if (metric == state.metric || !metric.availableFor(state.scope)) return;
    _fetch(state.scope, metric);
  }

  /// Switch the filter dimension, clearing the other's selection.
  void setDim(StatsFilterDim dim) {
    if (dim == state.dim) return;
    if (dim == StatsFilterDim.positions && state.scope == LeaderboardScope.teams) return;
    final hadSelection =
        state.filter.positions.isNotEmpty || state.filter.frameworks.isNotEmpty;
    emit(state.copyWith(
      dim: dim,
      filter: state.filter.copyWith(positions: const [], frameworks: const []),
    ));
    if (hadSelection) _refetchFiltered();
  }

  void togglePosition(String code) {
    final next = [...state.filter.positions];
    next.contains(code) ? next.remove(code) : next.add(code);
    emit(state.copyWith(
        filter: state.filter.copyWith(positions: next, frameworks: const [])));
    _refetchFiltered();
  }

  void toggleFramework(int id) {
    final next = [...state.filter.frameworks];
    next.contains(id) ? next.remove(id) : next.add(id);
    emit(state.copyWith(
        filter: state.filter.copyWith(frameworks: next, positions: const [])));
    _refetchFiltered();
  }

  void setRange({String? from, String? to}) {
    emit(state.copyWith(filter: state.filter.copyWith(from: from, to: to)));
    _refetchFiltered();
  }

  void clearFilters() {
    if (state.filter.isEmpty) return;
    emit(state.copyWith(filter: const LeaderboardFilter()));
    _refetchFiltered();
  }

  void _refetchFiltered() {
    _cache.clear();
    _fetch(state.scope, state.metric);
  }

  Future<void> _fetch(LeaderboardScope scope, LeaderboardMetric metric) async {
    final cached = _cache[(scope, metric)];
    if (cached != null) {
      emit(state.copyWith(
          scope: scope, metric: metric, status: LeaderboardStatus.ready, board: cached));
      return;
    }
    emit(state.copyWith(scope: scope, metric: metric, status: LeaderboardStatus.loading));
    final filter = state.filter;
    final res = await repo.getLeaderboard(scope, metric, filter: filter);
    if (isClosed) return;
    // Ignore a stale response if the user already switched away.
    if (scope != state.scope || metric != state.metric || filter != state.filter) return;
    res.fold(
      (f) => emit(state.copyWith(status: LeaderboardStatus.error, error: f.message)),
      (board) {
        _cache[(scope, metric)] = board;
        emit(state.copyWith(status: LeaderboardStatus.ready, board: board));
      },
    );
  }
}
