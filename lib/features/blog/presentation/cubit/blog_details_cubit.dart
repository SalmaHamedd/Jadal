import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/blog/domain/entities/blog_details.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';

part 'blog_details_state.dart';

class BlogDetailsCubit extends Cubit<BlogDetailsState> {
  final BlogRepository _repository;

  BlogDetailsCubit(this._repository) : super(BlogDetailsInitial());

  Future<void> loadBlogDetails(String slug) async {
    emit(BlogDetailsLoading());
    final result = await _repository.getBlogDetails(slug);
    result.fold(
      (failure) => emit(BlogDetailsError(failure.message)),
      (details) => emit(BlogDetailsLoaded(details)),
    );
  }
}