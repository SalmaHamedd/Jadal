part of 'login_cubit.dart';

abstract class LoginState extends Equatable {
  const LoginState();
}

class LoginInitial extends LoginState {
  @override
  List<Object> get props => [];
}

class LoginLoading extends LoginState {
  @override
  List<Object> get props => [];
}

class LoginSuccess extends LoginState {
  final String userId;
  const LoginSuccess(this.userId);
  @override
  List<Object> get props => [userId];
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
  @override
  List<Object> get props => [message];
}

/// Emitted whenever the password eye is toggled.
/// The [obscure] value is part of [props] on purpose: without it, two toggles
/// in a row would produce two "equal" states and Bloc would skip the rebuild.
class LoginPasswordVisibility extends LoginState {
  final bool obscure;
  const LoginPasswordVisibility(this.obscure);
  @override
  List<Object> get props => [obscure];
}