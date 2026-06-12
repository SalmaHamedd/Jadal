import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/services/message_service.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:permission_handler/permission_handler.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String? currentAvatarUrl; // optional, if you have it

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
    this.currentAvatarUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final EditProfileCubit _cubit;
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl; // local copy for immediate UI update

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    final repository = ProfileRepository();
    _cubit = EditProfileCubit(repository);
    _avatarUrl = widget.currentAvatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
    if (source == null) return;

    if (source == ImageSource.camera) {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final requested = await Permission.camera.request();
        if (!requested.isGranted) {
          MessageService.showError(context, 'Camera permission required');
          return;
        }
      }
    }

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      _cubit.uploadAvatar(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<EditProfileCubit, EditProfileState>(
          bloc: _cubit,
          listener: (context, state) {
            if (state is EditProfileSuccess) {
              MessageService.showSuccess(
                context,
                'Profile updated successfully',
              );
              Navigator.pop(context, state.updatedProfile);
            } else if (state is EditProfileError) {
              MessageService.showError(context, state.message);
            } else if (state is EditProfileAvatarUploaded) {
              // Update local avatar URL and show success
              setState(() {
                _avatarUrl = state.newAvatarUrl;
              });
              MessageService.showSuccess(context, 'Avatar updated');
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(context.wp(5)),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ProfileAvatar(
                              name: widget.currentName,
                              avatarUrl: _avatarUrl,
                            ),
                            if (state is! EditProfileAvatarUploading)
                              IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.blue,
                                ),
                                onPressed: _pickAndUploadImage,
                              )
                            else
                              const SizedBox(
                                height: 40,
                                width: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: context.hp(4)),
                        AuthTextField(
                          label: 'Name',
                          icon: Icons.person,
                          controller: _nameController,
                        ),
                        SizedBox(height: context.hp(2)),
                        AuthTextField(
                          label: 'Phone',
                          icon: Icons.phone,
                          controller: _phoneController,
                        ),
                        SizedBox(height: context.hp(3)),
                        AuthButton(
                          text: 'Save Changes',
                          onPressed: () {
                            _cubit.updateProfile(
                              name: _nameController.text.trim(),
                              phone: _phoneController.text.trim(),
                            );
                          },
                          isLoading: state is EditProfileLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
