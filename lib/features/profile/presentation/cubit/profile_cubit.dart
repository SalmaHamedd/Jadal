import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/profile.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;

  ProfileCubit(this._repository) : super(ProfileInitial());

  /// [warm] — §4.1: an already-in-flight result from the splash prefetch;
  /// when given it replaces the network call for this load only.
  Future<void> loadProfile({Future<Either<Failure, Profile>>? warm}) async {
    emit(ProfileLoading());
    final result = await (warm ?? _repository.getProfile());
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> logout() async {
    emit(ProfileLoading());
    final result = await _repository.logout();
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (message) => emit(ProfileLogoutSuccess(message)),
    );
  }
}
