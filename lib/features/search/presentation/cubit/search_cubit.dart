import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/search/domain/entities/search_team.dart';
import 'package:jadal_app/features/search/domain/entities/search_user.dart';
import 'package:jadal_app/features/search/domain/repositories/search_repository.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepository _repository;

  SearchCubit(this._repository) : super(SearchInitial());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());
    final result = await _repository.search(query: query.trim());
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (data) => emit(SearchLoaded(users: data.$1, teams: data.$2)),
    );
  }
}