part of 'blog_cubit.dart';

abstract class BlogState extends Equatable {
  const BlogState();
}

class BlogInitial extends BlogState {
  @override List<Object> get props => [];
}

class BlogLoading extends BlogState {
  @override List<Object> get props => [];
}

class BlogLoaded extends BlogState {
  final List<Blog> blogs;
  const BlogLoaded(this.blogs);
  @override List<Object> get props => [blogs];
}

class BlogError extends BlogState {
  final String message;
  const BlogError(this.message);
  @override List<Object> get props => [message];
}