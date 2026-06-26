part of 'create_blog_cubit.dart';

abstract class CreateBlogState extends Equatable {
  const CreateBlogState();
}

class CreateBlogInitial extends CreateBlogState {
  @override List<Object> get props => [];
}

class CreateBlogLoading extends CreateBlogState {
  @override List<Object> get props => [];
}

class CreateBlogSuccess extends CreateBlogState {
  final String message;
  const CreateBlogSuccess(this.message);
  @override List<Object> get props => [message];
}

class CreateBlogError extends CreateBlogState {
  final String message;
  const CreateBlogError(this.message);
  @override List<Object> get props => [message];
}