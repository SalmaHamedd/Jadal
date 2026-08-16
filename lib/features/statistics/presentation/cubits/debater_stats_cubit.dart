import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/app_models/framework.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/activity_stat_model.dart';
import '../../data/models/debater_stats_models.dart';
import '../../data/models/judge_rating_model.dart';
import '../../data/repositories/debater_stats_repository.dart';
import '../../data/repositories/team_analysis_repository.dart';

enum StatsStatus { initial, loading, loaded, error }

/// Which filter dimension is active. Position and framework are
/// mutually exclusive (the backend 422s when both are sent), so the UI keeps
/// exactly one dimension selectable and clears the other on switch.
enum StatsFilterDim { positions, frameworks }

/// One immutable snapshot driving the statistics screen. The currently-selected
/// [kind] decides which of [bucketed]/[ranking]/[improvement] the UI reads. The
/// model objects are kept across kind switches so the chart can animate from the
/// previous data to the new data instead of flashing empty.
class DebaterStatsState {
  final StatKind kind;
  final StatsFilter filter;
  final StatsFilterDim dim;
  final List<Framework> frameworkOptions;
  final RankingMode rankingMode;
  final int rankingLimit;
  final StatsStatus status;
  final BucketedStat? bucketed;
  final ScoreRanking? ranking;
  final ImprovementStat? improvement;
  final ActivityStat? activity;
  final JudgeRatingStat? judgeRating;
  final String? error;

  /// Monotonically increasing id of the latest fetch — lets the cubit drop the
  /// result of a superseded request (rapid filter taps) without races.
  final int requestId;

  const DebaterStatsState({
    required this.kind,
    required this.filter,
    this.dim = StatsFilterDim.positions,
    this.frameworkOptions = const [],
    required this.rankingMode,
    required this.rankingLimit,
    required this.status,
    this.bucketed,
    this.ranking,
    this.improvement,
    this.activity,
    this.judgeRating,
    this.error,
    required this.requestId,
  });

  factory DebaterStatsState.initial({StatKind kind = StatKind.winRate}) =>
      DebaterStatsState(
        kind: kind,
        filter: const StatsFilter(),
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
    StatsFilterDim? dim,
    List<Framework>? frameworkOptions,
    RankingMode? rankingMode,
    int? rankingLimit,
    StatsStatus? status,
    BucketedStat? bucketed,
    ScoreRanking? ranking,
    ImprovementStat? improvement,
    ActivityStat? activity,
    JudgeRatingStat? judgeRating,
    String? error,
    bool clearError = false,
    int? requestId,
  }) {
    return DebaterStatsState(
      kind: kind ?? this.kind,
      filter: filter ?? this.filter,
      dim: dim ?? this.dim,
      frameworkOptions: frameworkOptions ?? this.frameworkOptions,
      rankingMode: rankingMode ?? this.rankingMode,
      rankingLimit: rankingLimit ?? this.rankingLimit,
      status: status ?? this.status,
      bucketed: bucketed ?? this.bucketed,
      ranking: ranking ?? this.ranking,
      improvement: improvement ?? this.improvement,
      activity: activity ?? this.activity,
      judgeRating: judgeRating ?? this.judgeRating,
      error: clearError ? null : (error ?? this.error),
      requestId: requestId ?? this.requestId,
    );
  }
}

/// Drives the statistics screen: holds the shared filter + selected stat and
/// re-fetches whenever either changes. Every setter emits immediately (so the
/// chips feel instant) then loads the matching endpoint.
/// [subjectRole] gates the debater-only stats: for judges/trainers the
/// screen only ever shows activity, so the cubit starts on it and never leaves.
class DebaterStatsCubit extends Cubit<DebaterStatsState> {
  final DebaterStatsRepository repo;
  final int debaterId;
  final String subjectRole;

  /// Loads the framework filter options (`GET /motion-frameworks`);
  /// injected so the statistics feature doesn't depend on the live-debate repo.
  final Future<Either<Failure, List<Framework>>> Function()? frameworksLoader;

  /// Judge ratings live on their own endpoint, outside the
  /// debater-stats repository.
  final TeamAnalysisRepository _analysisRepo = TeamAnalysisRepository();

  DebaterStatsCubit({
    required this.repo,
    required this.debaterId,
    this.subjectRole = 'debater',
    this.frameworksLoader,
  }) : super(DebaterStatsState.initial(
          kind: subjectRole == 'debater' ? StatKind.winRate : StatKind.activity,
        ));

  void load() {
    _fetch();
    _loadFrameworkOptions();
  }

  Future<void> _loadFrameworkOptions() async {
    if (frameworksLoader == null || subjectRole != 'debater') return;
    if (state.frameworkOptions.isNotEmpty) return;
    final res = await frameworksLoader!();
    if (isClosed) return;
    // Silently keep an empty list on failure — the dimension chip stays
    // usable and simply has nothing to select.
    res.fold((_) {}, (list) => emit(state.copyWith(frameworkOptions: list)));
  }

  /// The grouping the user had on a chart stat, parked while activity forces
  /// its own default so switching back doesn't silently reset it.
  StatsGroupBy? _groupByBeforeActivity;

  void setKind(StatKind kind) {
    if (kind == state.kind) return;
    var filter = state.filter;
    // Activity's chart needs ≥2 buckets, and the screen used to
    // leave group_by at `none` (one all-time bucket), so the trend line was
    // unreachable. Default it to monthly on entry and restore the user's own
    // grouping when they leave.
    if (kind == StatKind.activity && state.kind != StatKind.activity) {
      _groupByBeforeActivity = filter.groupBy;
      filter = filter.copyWith(groupBy: StatsGroupBy.month);
    } else if (kind != StatKind.activity && state.kind == StatKind.activity) {
      filter = filter.copyWith(
        groupBy: _groupByBeforeActivity ?? StatsGroupBy.none,
      );
      _groupByBeforeActivity = null;
    }
    emit(state.copyWith(kind: kind, filter: filter, clearError: true));
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

  /// Switch the active filter dimension. Clears the *other* dimension's
  /// selection (they are mutually exclusive) and resets the series split, which
  /// is tied to the active dimension.
  void setDim(StatsFilterDim dim) {
    if (dim == state.dim) return;
    final hadSelection =
        state.filter.positions.isNotEmpty || state.filter.frameworks.isNotEmpty;
    final hadSeries = state.filter.series != StatsSeries.none;
    emit(state.copyWith(
      dim: dim,
      filter: state.filter.copyWith(
        positions: const [],
        frameworks: const [],
        series: StatsSeries.none,
      ),
    ));
    // Only refetch when the switch actually changed the outgoing query.
    if (hadSelection || hadSeries) _fetch();
  }

  void togglePosition(String code) {
    final next = [...state.filter.positions];
    next.contains(code) ? next.remove(code) : next.add(code);
    // Never combined with frameworks.
    emit(state.copyWith(
        filter: state.filter.copyWith(positions: next, frameworks: const [])));
    _fetch();
  }

  void toggleFramework(int id) {
    final next = [...state.filter.frameworks];
    next.contains(id) ? next.remove(id) : next.add(id);
    // Never combined with positions.
    emit(state.copyWith(
        filter: state.filter.copyWith(frameworks: next, positions: const [])));
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
        // Was `const StatsFilter`, which pinned every activity
        // request to group_by=none no matter what the user picked, so the
        // response only ever had one bucket and the trend chart could never
        // render. The real filter goes through now; the repository already
        // strips the dimensions this endpoint doesn't accept, keeping only
        // from/to/group_by.
        final res = await repo.getActivity(debaterId, filter,
            role: subjectRole);
        if (id != state.requestId) return;
        res.fold(
          (l) => emit(state.copyWith(status: StatsStatus.error, error: l.message)),
          (r) => emit(state.copyWith(status: StatsStatus.loaded, activity: r)),
        );
      case StatKind.judgeRating:
        // Judges only. Takes from/to/group_by/frameworks; there is
        // no position dimension for a judge.
        final res = await _analysisRepo.getJudgeRatings(
          debaterId,
          from: filter.from,
          to: filter.to,
          groupBy: filter.groupBy,
          frameworks: filter.frameworks,
        );
        if (id != state.requestId) return;
        res.fold(
          (l) => emit(state.copyWith(status: StatsStatus.error, error: l.message)),
          (r) => emit(state.copyWith(status: StatsStatus.loaded, judgeRating: r)),
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
