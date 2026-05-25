import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final EditProfileCubit _cubit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    final repository = ProfileRepository();
    _cubit = EditProfileCubit(repository);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<EditProfileCubit, EditProfileState>(
          bloc: _cubit,
          listener: (context, state) {
            if (state is EditProfileSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
              Navigator.pop(context, state.updatedProfile);
            } else if (state is EditProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
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
                        ProfileAvatar(name: widget.currentName),
                        SizedBox(height: context.hp(2)),
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