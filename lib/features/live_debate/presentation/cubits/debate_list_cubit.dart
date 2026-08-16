import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/debate_list_model.dart';
import '../../data/repositories/live_debate_repository.dart';

enum DebateListStatus { initial, loading, ready, loadingMore, error }

/// One status tab's paginated list state.
class DebateListState {
  final DebateListStatus status;
  final List<DebateListItem> items;
  final PaginationMeta? meta;
  final String? error;

  const DebateListState({
    this.status = DebateListStatus.initial,
    this.items = const [],
    this.meta,
    this.error,
  });

  bool get hasMore => meta?.hasMore ?? false;

  DebateListState copyWith({
    DebateListStatus? status,
    List<DebateListItem>? items,
    PaginationMeta? meta,
    String? error,
  }) =>
      DebateListState(
        status: status ?? this.status,
        items: items ?? this.items,
        meta: meta ?? this.meta,
        error: error,
      );
}

/// Loads one debate-list tab from `GET /debates?status=…` with `meta`-driven
/// pagination. One instance per tab.
class DebateListCubit extends Cubit<DebateListState> {
  final LiveDebateRepository repo;
  final String statusFilter; // wire value (e.g. 'scheduled', 'teams-selected')
  final int perPage;
  bool _loadingMore = false;

  DebateListCubit({
    required this.repo,
    required this.statusFilter,
    this.perPage = 15,
  }) : super(const DebateListState());

  Future<void> load() async {
    emit(state.copyWith(status: DebateListStatus.loading));
    final res = await repo.getDebates(status: statusFilter, page: 1, perPage: perPage);
    res.fold(
      (f) => emit(state.copyWith(status: DebateListStatus.error, error: f.message)),
      (page) => emit(DebateListState(
        status: DebateListStatus.ready,
        items: page.items,
        meta: page.meta,
      )),
    );
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (_loadingMore || !state.hasMore || state.status != DebateListStatus.ready) return;
    _loadingMore = true;
    emit(state.copyWith(status: DebateListStatus.loadingMore));
    final next = (state.meta?.currentPage ?? 1) + 1;
    final res = await repo.getDebates(status: statusFilter, page: next, perPage: perPage);
    res.fold(
      (f) => emit(state.copyWith(status: DebateListStatus.ready, error: f.message)),
      (page) => emit(DebateListState(
        status: DebateListStatus.ready,
        items: [...state.items, ...page.items],
        meta: page.meta,
      )),
    );
    _loadingMore = false;
  }
}
