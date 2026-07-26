import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/profile.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;

  ProfileCubit(this._repository) : super(ProfileInitial());

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    final result = await _repository.getProfile();
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  /// V2 §9 — optimistic isn't needed here: the PUT returns the fresh profile,
  /// so we re-emit ProfileLoaded from the response. On failure the previous
  /// loaded state is kept (the switch snaps back) and an error surfaces via
  /// the listener's snackbar path.
  Future<void> setStatsVisibility(bool visible) async {
    final previous = state;
    final result = await _repository.setStatsVisibility(visible);
    result.fold(
      (failure) {
        emit(ProfileError(failure.message));
        if (previous is ProfileLoaded) emit(ProfileLoaded(previous.profile));
      },
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
