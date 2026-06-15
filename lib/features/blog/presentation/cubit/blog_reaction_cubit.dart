import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';

part 'blog_reaction_state.dart';

class BlogReactionCubit extends Cubit<BlogReactionState> {
  final BlogRepository _repository;
  BlogReactionCubit(this._repository) : super(BlogReactionInitial());

  Future<void> reactToBlog(int blogId, String type) async {
    final isUndo =
        (state is BlogReactionSuccess &&
        (state as BlogReactionSuccess).currentReaction == type);

    emit(BlogReactionLoading());
    final result = await _repository.reactToBlog(blogId: blogId, type: type);
    result.fold((failure) => emit(BlogReactionError(failure.message)), (data) {
      final likes = data['likes_count']!;
      final dislikes = data['dislikes_count']!;
      final newReaction = isUndo ? null : type;
      emit(BlogReactionSuccess(likes, dislikes, newReaction));
    });
  }

  Future<bool> reactToBlogRaw(int blogId, String type) async {
    final result = await _repository.reactToBlog(blogId: blogId, type: type);
    return result.fold((failure) => false, (data) => true);
  }
}
