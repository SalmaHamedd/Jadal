part of 'blog_details_cubit.dart';

abstract class BlogDetailsState extends Equatable {
  const BlogDetailsState();
}

class BlogDetailsInitial extends BlogDetailsState {
  @override List<Object> get props => [];
}

class BlogDetailsLoading extends BlogDetailsState {
  @override List<Object> get props => [];
}

class BlogDetailsLoaded extends BlogDetailsState {
  final BlogDetails blogDetails;
  const BlogDetailsLoaded(this.blogDetails);
  @override List<Object> get props => [blogDetails];
}

class BlogDetailsError extends BlogDetailsState {
  final String message;
  const BlogDetailsError(this.message);
  @override List<Object> get props => [message];
}