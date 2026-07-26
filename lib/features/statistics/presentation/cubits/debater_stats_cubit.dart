import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/activity_stat_model.dart';
import '../../data/models/debater_stats_models.dart';
import '../../data/repositories/debater_stats_repository.dart';

enum StatsStatus { initial, loading, loaded, error }

/// One immutable snapshot driving the statistics screen. The currently-selected
/// [kind] decides which of [bucketed]/[ranking]/[improvement] the UI reads. The
/// model objects are kept across kind switches so the chart can animate from the
/// previous data to the new data instead of flashing empty.
class DebaterStatsState {
  final StatKind kind;
  final StatsFilter filter;
  final RankingMode rankingMode;
  final int rankingLimit;
  final StatsStatus status;
  final BucketedStat? bucketed;
  final ScoreRanking? ranking;
  final ImprovementStat? improvement;
  final ActivityStat? activity;
  final String? error;

  /// Monotonically increasing id of the latest fetch — lets the cubit drop the
  /// result of a superseded request (rapid filter taps) without races.
  final int requestId;

  const DebaterStatsState({
    required this.kind,
    required this.filter,
    required this.rankingMode,
    required this.rankingLimit,
    required this.status,
    this.bucketed,
    this.ranking,
    this.improvement,
    this.activity,
    this.error,
    required this.requestId,
  });

  factory DebaterStatsState.initial() => const DebaterStatsState(
        kind: StatKind.winRate,
        filter: StatsFilter(),
        rankingMode: RankingMode.top,
        rankingLimit: 10,
        status: StatsStatus.initial,
        requestId: 0,
      );

  bool get isBucketed =>
      kind == StatKind.winRate || kind == StatKind.avgScore || kind == StatKind.bestSpeaker;

  DebaterStatsState copyWith({
    StatKind? kind,
    StatsFilter? filter,
    RankingMode? rankingMode,
    int? rankingLimit,
    StatsStatus? status,
    BucketedStat? bucketed,
    ScoreRanking? ranking,
    ImprovementStat? improvement,
    ActivityStat? activity,
    String? error,
    bool clearError = false,
    int? requestId,
  }) {
    return DebaterStatsState(
      kind: kind ?? this.kind,
      filter: filter ?? this.filter,
      rankingMode: rankingMode ?? this.rankingMode,
      rankingLimit: rankingLimit ?? this.rankingLimit,
      status: status ?? this.status,
      bucketed: bucketed ?? this.bucketed,
      ranking: ranking ?? this.ranking,
      improvement: improvement ?? this.improvement,
      activity: activity ?? this.activity,
      error: clearError ? null : (error ?? this.error),
      requestId: requestId ?? this.requestId,
    );
  }
}

/// Drives the statistics screen: holds the shared filter + selected stat and
/// re-fetches whenever either changes. Every setter emits immediately (so the
/// chips feel instant) then loads the matching endpoint.
class DebaterStatsCubit extends Cubit<DebaterStatsState> {
  final DebaterStatsRepository repo;
  final int debaterId;

  DebaterStatsCubit({required this.repo, required this.debaterId})
      : super(DebaterStatsState.initial());

  void load() => _fetch();

  void setKind(StatKind kind) {
    if (kind == state.kind) return;
    emit(state.copyWith(kind: kind, clearError: true));
    _fetch();
  }

  void setGroupBy(StatsGroupBy groupBy) {
    emit(state.copyWith(filter: state.filter.copyWith(groupBy: groupBy)));
    _fetch();
  }

  void setSeries(StatsSeries series) {
    emit(state.copyWith(filter: state.filter.copyWith(series: series)));
    _fetch();
  }

  void togglePosition(String code) {
    final next = [...state.filter.positions];
    next.contains(code) ? next.remove(code) : next.add(code);
    emit(state.copyWith(filter: state.filter.copyWith(positions: next)));
    _fetch();
  }

  void setRange({String? from, String? to, bool clearFrom = false, bool clearTo = false}) {
    emit(state.copyWith(
      filter: state.filter.copyWith(from: from, to: to, clearFrom: clearFrom, clearTo: clearTo),
    ));
    _fetch();
  }

  void setRankingMode(RankingMode mode) {
    emit(state.copyWith(rankingMode: mode));
    _fetch();
  }

  void clearFilters() {
    emit(state.copyWith(
      filter: const StatsFilter(),
      rankingMode: RankingMode.top,
    ));
    _fetch();
  }

  Future<void> _fetch() async {
    final id = state.requestId + 1;
    emit(state.copyWith(status: StatsStatus.loading, requestId: id, clearError: true));
    final filter = state.filter;

    switch (state.kind) {
      case StatKind.winRate:
        _settleBucketed(id, await repo.getWinRate(debaterId, filter));
      case StatKind.avgScore:
        _settleBucketed(id, await repo.getAvgScore(debaterId, filter));
      case StatKind.bestSpeaker:
        _settleBucketed(id, await repo.getBestSpeaker(debaterId, filter));
      case StatKind.ranking:
        final res = await repo.getScoreRanking(
          debaterId,
          filter,
          mode: state.rankingMode,
          limit: state.rankingLimit,
        );
        if (id != state.requestId) return;
        res.fold(
          (l) => emit(state.copyWith(status: StatsStatus.error, error: l.message)),
          (r) => emit(state.copyWith(status: StatsStatus.loaded, ranking: r)),
        );
      case StatKind.improvement:
        final res = await repo.getImprovement(debaterId, filter);
        if (id != state.requestId) return;
        res.fold(
          (l) => emit(state.copyWith(status: StatsStatus.error, error: l.message)),
          (r) => emit(state.copyWith(status: StatsStatus.loaded, improvement: r)),
        );
      case StatKind.activity:
        final res = await repo.getActivity(debaterId, filter);
        if (id != state.requestId) return;
        res.fold(
          (l) => emit(state.copyWith(status: StatsStatus.error, error: l.message)),
          (r) => emit(state.copyWith(status: StatsStatus.loaded, activity: r)),
        );
    }
  }

  void _settleBucketed(int id, Either<Failure, BucketedStat> res) {
    if (id != state.requestId) return; // superseded by a newer request
    res.fold(
      (l) => emit(state.copyWith(status: StatsStatus.error, error: l.message)),
      (r) => emit(state.copyWith(status: StatsStatus.loaded, bucketed: r)),
    );
  }
}
