part of 'change_password_cubit.dart';

abstract class ChangePasswordState extends Equatable {
  const ChangePasswordState();
}

class ChangePasswordInitial extends ChangePasswordState {
  @override
  List<Object> get props => [];
}

class ChangePasswordLoading extends ChangePasswordState {
  @override
  List<Object> get props => [];
}

class ChangePasswordSuccess extends ChangePasswordState {
  final String message;
  const ChangePasswordSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class ChangePasswordError extends ChangePasswordState {
  final String message;
  const ChangePasswordError(this.message);
  @override
  List<Object> get props => [message];
}