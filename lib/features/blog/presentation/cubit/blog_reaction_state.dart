part of 'blog_reaction_cubit.dart';

/// Single source of truth for a blog's like/dislike counts and the caller's
/// own reaction — everything the reaction row needs, including which button
/// (if any) has a request in flight, so only *that* button disables/spins.
class BlogReactionState extends Equatable {
  final int likes;
  final int dislikes;
  final String? currentReaction;
  final String? reactingType;
  final String? error;

  const BlogReactionState({
    this.likes = 0,
    this.dislikes = 0,
    this.currentReaction,
    this.reactingType,
    this.error,
  });

  bool get isReacting => reactingType != null;

  @override
  List<Object?> get props => [likes, dislikes, currentReaction, reactingType, error];
}
