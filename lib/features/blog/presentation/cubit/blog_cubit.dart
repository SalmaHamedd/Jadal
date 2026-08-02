import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/blog/domain/blog_search_filter.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';

part 'blog_state.dart';

class BlogCubit extends Cubit<BlogState> {
  final BlogRepository repository;

  BlogCubit(this.repository) : super(BlogInitial());

  /// [warm] — §4.1: an already-in-flight result from the splash prefetch;
  /// when given it replaces the network call for this load only.
  Future<void> loadBlogs({Future<Either<Failure, List<Blog>>>? warm}) async {
    emit(BlogLoading());
    final result = await (warm ?? repository.getBlogs());
    result.fold(
      (failure) => emit(BlogError(failure.message)),
      (blogs) => emit(BlogLoaded(blogs)),
    );
  }

  /// Search + filter (§10) — replaces the plain list load whenever a query or
  /// filter is active.
  Future<void> searchBlogs(BlogSearchFilter filter) async {
    emit(BlogLoading());
    final result = await repository.searchBlogs(
      q: filter.q,
      categoryIds: filter.categoryIds,
      tagIds: filter.tagIds,
      publisherId: filter.publisherId,
      likedByMe: filter.likedByMe,
    );
    result.fold(
      (failure) => emit(BlogError(failure.message)),
      (blogs) => emit(BlogLoaded(blogs)),
    );
  }
}