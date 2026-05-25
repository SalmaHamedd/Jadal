import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';

part 'change_password_state.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final ProfileRepository _repository;

  ChangePasswordCubit(this._repository) : super(ChangePasswordInitial());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    emit(ChangePasswordLoading());
    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    result.fold(
      (failure) => emit(ChangePasswordError(failure.message)),
      (message) => emit(ChangePasswordSuccess(message)),
    );
  }
}