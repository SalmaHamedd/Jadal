import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/repositories/auth_repository.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository;

  LoginCubit(this._repository) : super(LoginInitial());

  /// Pure UI state, but driven through the cubit as you asked.
  bool obscurePassword = true;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    emit(LoginPasswordVisibility(obscurePassword));
  }

Future<void> login(String email, String password) async {
  emit(LoginLoading());
  final result = await _repository.login(email, password);
  result.fold(
    (failure) => emit(LoginFailure(failure.message)),
    (user) => emit(LoginSuccess(user.id.toString())),
  );
}
}