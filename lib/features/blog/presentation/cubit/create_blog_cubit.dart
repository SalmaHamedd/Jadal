import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';

part 'create_blog_state.dart';

class CreateBlogCubit extends Cubit<CreateBlogState> {
  final BlogRepository _repository;
  CreateBlogCubit(this._repository) : super(CreateBlogInitial());

  Future<void> createBlog({
    required String title,
    required String content,
    String? coverImageUrl,
    List<int>? categoryIds,
    List<int>? tagIds, String? coverImage,
  }) async {
    emit(CreateBlogLoading());
    final result = await _repository.createBlog(
      title: title,
      content: content,
      coverImageUrl: coverImageUrl,
      categoryIds: categoryIds,
      tagIds: tagIds,
    );
    result.fold(
      (failure) => emit(CreateBlogError(failure.message)),
      (blog) => emit(CreateBlogSuccess('تم إرسال المقال للمراجعة بنجاح')),
    );
  }
}