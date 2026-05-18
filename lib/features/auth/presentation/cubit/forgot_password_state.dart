part of 'forgot_password_cubit.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();
}

class ForgotPasswordInitial extends ForgotPasswordState {
  @override
  List<Object> get props => [];
}

class ForgotPasswordLoading extends ForgotPasswordState {
  @override
  List<Object> get props => [];
}

class ForgotPasswordSuccess extends ForgotPasswordState {
  final String message;
  const ForgotPasswordSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String message;
  const ForgotPasswordFailure(this.message);
  @override
  List<Object> get props => [message];
}