import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:permission_handler/permission_handler.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String? currentAvatarUrl;
  final String? currentLocation;
  final String? currentBirthDate;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
    this.currentAvatarUrl,
    this.currentLocation,
    this.currentBirthDate,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final EditProfileCubit _cubit;
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _locationController = TextEditingController(text: widget.currentLocation ?? '');
    final repository = ProfileRepository();
    _cubit = EditProfileCubit(repository);
    _avatarUrl = widget.currentAvatarUrl;
    _birthDate = widget.currentBirthDate != null ? DateTime.tryParse(widget.currentBirthDate!) : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
          if (!mounted) return;
          JadalSnackBar.show(context, 'Camera permission required', type: SnackBarType.error);
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
              JadalSnackBar.show(context, 'Profile updated successfully', type: SnackBarType.success);
              Navigator.pop(context, state.updatedProfile);
            } else if (state is EditProfileError) {
              JadalSnackBar.show(context, state.message, type: SnackBarType.error);
            } else if (state is EditProfileAvatarUploaded) {
              setState(() {
                _avatarUrl = state.newAvatarUrl;
              });
              JadalSnackBar.show(context, 'Avatar updated', type: SnackBarType.success);
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
                        SizedBox(height: context.hp(2)),
                        AuthTextField(
                          label: 'Location',
                          icon: Icons.location_on_outlined,
                          controller: _locationController,
                        ),
                        SizedBox(height: context.hp(2)),
                        InkWell(
                          onTap: _pickBirthDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Birth date',
                              prefixIcon: Icon(Icons.cake_outlined),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_birthDate != null ? _formatDate(_birthDate!) : 'Not set'),
                          ),
                        ),
                        SizedBox(height: context.hp(3)),
                        AuthButton(
                          text: 'Save Changes',
                          onPressed: () {
                            _cubit.updateProfile(
                              name: _nameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              location: _locationController.text.trim(),
                              birthDate: _birthDate != null ? _formatDate(_birthDate!) : null,
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