part of 'edit_profile_cubit.dart';

abstract class EditProfileState extends Equatable {
  const EditProfileState();
}

class EditProfileInitial extends EditProfileState {
  @override
  List<Object> get props => [];
}

class EditProfileLoading extends EditProfileState {
  @override
  List<Object> get props => [];
}

class EditProfileSuccess extends EditProfileState {
  final Profile updatedProfile;
  const EditProfileSuccess(this.updatedProfile);
  @override
  List<Object> get props => [updatedProfile];
}

class EditProfileError extends EditProfileState {
  final String message;
  const EditProfileError(this.message);
  @override
  List<Object> get props => [message];
}

class EditProfileAvatarUploading extends EditProfileState {
  @override
  List<Object> get props => [];
}

class EditProfileAvatarUploaded extends EditProfileState {
  final String newAvatarUrl;
  const EditProfileAvatarUploaded(this.newAvatarUrl);
  @override
  List<Object> get props => [newAvatarUrl];
}
