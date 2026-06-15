part of 'blog_reaction_cubit.dart';

abstract class BlogReactionState extends Equatable {
  const BlogReactionState();
}

class BlogReactionInitial extends BlogReactionState {
  @override List<Object> get props => [];
}

class BlogReactionLoading extends BlogReactionState {
  @override List<Object> get props => [];
}

class BlogReactionSuccess extends BlogReactionState {
  final int likesCount;
  final int dislikesCount;
  final String? currentReaction;

  const BlogReactionSuccess(this.likesCount, this.dislikesCount, this.currentReaction);

  @override List<Object?> get props => [likesCount, dislikesCount, currentReaction];
}

class BlogReactionError extends BlogReactionState {
  final String message;
  const BlogReactionError(this.message);
  @override List<Object> get props => [message];
}