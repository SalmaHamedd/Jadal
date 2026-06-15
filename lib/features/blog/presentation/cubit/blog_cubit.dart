import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';

part 'blog_state.dart';

class BlogCubit extends Cubit<BlogState> {
  final BlogRepository repository;

  BlogCubit(this.repository) : super(BlogInitial());

  Future<void> loadBlogs() async {
    emit(BlogLoading());
    final result = await repository.getBlogs();
    result.fold(
      (failure) => emit(BlogError(failure.message)),
      (blogs) => emit(BlogLoaded(blogs)),
    );
  }
}