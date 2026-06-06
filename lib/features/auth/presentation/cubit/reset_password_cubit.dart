import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/auth/data/repositories/auth_repository.dart';

part 'reset_password_state.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final AuthRepository _repository;

  ResetPasswordCubit(this._repository) : super(ResetPasswordInitial());

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