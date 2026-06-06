part of 'reset_password_cubit.dart';

abstract class ResetPasswordState extends Equatable {
  const ResetPasswordState();
}

class ResetPasswordInitial extends ResetPasswordState {
  @override
  List<Object> get props => [];
}

class ResetPasswordLoading extends ResetPasswordState {
  @override
  List<Object> get props => [];
}

class ResetPasswordSuccess extends ResetPasswordState {
  final String message;
  const ResetPasswordSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class ResetPasswordFailure extends ResetPasswordState {
  final String message;
  const ResetPasswordFailure(this.message);
  @override
  List<Object> get props => [message];
}