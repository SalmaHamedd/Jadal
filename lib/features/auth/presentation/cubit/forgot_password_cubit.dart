import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/auth/data/repositories/auth_repository.dart';

part 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _repository;

  ForgotPasswordCubit(this._repository) : super(ForgotPasswordInitial());

  Future<void> forgotPassword(String email) async {
    emit(ForgotPasswordLoading());

    if (email.isEmpty) {
      emit(const ForgotPasswordFailure('Please enter your email'));
      return;
    }

    final result = await _repository.forgotPassword(email);
    result.fold(
      (failure) => emit(ForgotPasswordFailure(failure.message)),
      (message) => emit(ForgotPasswordSuccess(message)), 
    );
  }
}