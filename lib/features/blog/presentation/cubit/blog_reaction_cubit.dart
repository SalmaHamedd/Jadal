import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';

part 'blog_reaction_state.dart';

/// Owns one blog's reaction row end to end: seeds counts from the details
/// payload, restores the caller's own previous reaction from local storage
/// (the API doesn't echo it back), and applies/rolls back optimistic
/// updates around the actual `react` call — the widget just renders [state].
class BlogReactionCubit extends Cubit<BlogReactionState> {
  final BlogRepository _repository;
  final PreferencesDatabase _prefs;
  int? _blogId;
  String? _slug;

  BlogReactionCubit(this._repository, {PreferencesDatabase? prefs})
      : _prefs = prefs ?? PreferencesDatabase(),
        super(const BlogReactionState());

  Future<void> init({
    required int blogId,
    required String slug,
    required int likes,
    required int dislikes,
  }) async {
    _blogId = blogId;
    _slug = slug;
    final userId = await _prefs.getValue<int>('user_id');
    final savedReaction = userId != null
        ? await _prefs.getValue<String>('reaction_${userId}_$slug')
        : null;
    emit(BlogReactionState(likes: likes, dislikes: dislikes, currentReaction: savedReaction));
  }

  Future<void> react(String type) async {
    final blogId = _blogId;
    if (state.isReacting || blogId == null) return;

    final prevLikes = state.likes;
    final prevDislikes = state.dislikes;
    final prevReaction = state.currentReaction;

    int likes = prevLikes;
    int dislikes = prevDislikes;
    String? reaction;

    if (prevReaction == type) {
      // Tapping the active reaction again removes it.
      reaction = null;
      if (type == 'like') {
        likes--;
      } else {
        dislikes--;
      }
    } else {
      reaction = type;
      if (type == 'like') {
        likes++;
        if (prevReaction == 'dislike') dislikes--;
      } else {
        dislikes++;
        if (prevReaction == 'like') likes--;
      }
    }

    emit(BlogReactionState(
      likes: likes,
      dislikes: dislikes,
      currentReaction: reaction,
      reactingType: type,
    ));

    final result = await _repository.reactToBlog(blogId: blogId, type: type);
    await result.fold(
      (failure) async {
        // Roll back counts *and* the reaction flag together — leaving them
        // out of sync was the original bug (button showed "liked" with a
        // count that never moved).
        emit(BlogReactionState(
          likes: prevLikes,
          dislikes: prevDislikes,
          currentReaction: prevReaction,
          error: failure.message,
        ));
      },
      (data) async {
        emit(BlogReactionState(
          likes: data['likes_count'] ?? likes,
          dislikes: data['dislikes_count'] ?? dislikes,
          currentReaction: reaction,
        ));
        await _saveReaction(reaction);
      },
    );
  }

  Future<void> _saveReaction(String? reaction) async {
    final slug = _slug;
    if (slug == null) return;
    final userId = await _prefs.getValue<int>('user_id');
    if (userId == null) return;
    final key = 'reaction_${userId}_$slug';
    if (reaction == null) {
      await _prefs.removeValue(key);
    } else {
      await _prefs.setValue(key, reaction);
    }
  }

  /// Clears a shown error without touching counts/reaction, so the
  /// listener that displayed it doesn't re-show the same message.
  void dismissError() {
    if (state.error == null) return;
    emit(BlogReactionState(
      likes: state.likes,
      dislikes: state.dislikes,
      currentReaction: state.currentReaction,
    ));
  }
}
