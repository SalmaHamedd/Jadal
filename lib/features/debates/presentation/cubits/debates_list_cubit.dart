import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/debate.dart';
import '../../domain/repositories/debate_repositories.dart';

enum DebatesListStatus { initial, loading, refreshing, ready, error }

enum JudgeFilter { all, openForJudges, assignedToMe }

class DebatesListState extends Equatable {
  final DebatesListStatus status;
  final List<Debate> debates;
  final JudgeFilter judgeFilter;
  final String? error;

  const DebatesListState({
    this.status = DebatesListStatus.initial,
    this.debates = const [],
    this.judgeFilter = JudgeFilter.all,
    this.error,
  });

  DebatesListState copyWith({
    DebatesListStatus? status,
    List<Debate>? debates,
    JudgeFilter? judgeFilter,
    String? error,
    bool clearError = false,
  }) =>
      DebatesListState(
        status: status ?? this.status,
        debates: debates ?? this.debates,
        judgeFilter: judgeFilter ?? this.judgeFilter,
        error: clearError ? null : (error ?? this.error),
      );

  List<Debate> get upcoming =>
      debates.where((d) => d.status == DebateLifecycle.upcoming).toList();
  List<Debate> get live =>
      debates.where((d) => d.status == DebateLifecycle.live).toList();
  List<Debate> get past =>
      debates.where((d) => d.status == DebateLifecycle.past).toList();

  @override
  List<Object?> get props => [status, debates, judgeFilter, error];
}

class DebatesListCubit extends Cubit<DebatesListState> {
  final DebatesRepository _repo;

  DebatesListCubit(this._repo) : super(const DebatesListState());

  Future<void> load() async {
    if (state.status == DebatesListStatus.ready) {
      emit(state.copyWith(status: DebatesListStatus.refreshing));
    } else {
      emit(state.copyWith(status: DebatesListStatus.loading));
    }
    try {
      final list = await _repo.fetchDebates();
      emit(state.copyWith(
        status: DebatesListStatus.ready,
        debates: list,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: DebatesListStatus.error, error: e.toString()));
    }
  }

  void setJudgeFilter(JudgeFilter filter) {
    emit(state.copyWith(judgeFilter: filter));
  }
}
