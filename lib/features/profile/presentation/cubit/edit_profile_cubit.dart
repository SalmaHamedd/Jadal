import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/profile.dart';

part 'edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  final ProfileRepository _repository;

  EditProfileCubit(this._repository) : super(EditProfileInitial());

  Future<void> updateProfile({
    required String name,
    required String phone,
    String? birthDate,
    String? location,
  }) async {
    emit(EditProfileLoading());
    final result = await _repository.updateProfile(
      name: name,
      phone: phone,
      birthDate: birthDate,
      location: location,
    );
    result.fold(
      (failure) => emit(EditProfileError(failure.message)),
      (updatedProfile) => emit(EditProfileSuccess(updatedProfile)),
    );
  }

  Future<void> uploadAvatar(File imageFile) async {
    emit(EditProfileAvatarUploading());
    final result = await _repository.uploadAvatar(imageFile);
    result.fold(
      (failure) => emit(EditProfileError(failure.message)),
      (newUrl) => emit(EditProfileAvatarUploaded(newUrl)),
    );
  }
}
