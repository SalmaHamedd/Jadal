import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/repositories/auth_repository.dart';

part 'reset_password_state.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final AuthRepository _repository;

  ResetPasswordCubit(this._repository) : super(ResetPasswordInitial());

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    emit(
      ResetPasswordVisibility(
        obscurePassword: obscurePassword,
        obscureConfirmPassword: obscureConfirmPassword,
      ),
    );
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    emit(
      ResetPasswordVisibility(
        obscurePassword: obscurePassword,
        obscureConfirmPassword: obscureConfirmPassword,
      ),
    );
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(ResetPasswordLoading());
    final result = await _repository.resetPassword(
      email: email,
      token: token,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    result.fold(
      (failure) => emit(ResetPasswordFailure(failure.message)),
      (message) => emit(ResetPasswordSuccess(message)),
    );
  }
}
