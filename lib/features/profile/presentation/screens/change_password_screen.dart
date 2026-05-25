import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/change_password_cubit.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  late final ChangePasswordCubit _cubit;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    final repository = ProfileRepository();
    _cubit = ChangePasswordCubit(repository);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
          bloc: _cubit,
          listener: (context, state) {
            if (state is ChangePasswordSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              Navigator.pop(context);
            } else if (state is ChangePasswordError) {
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
                        const Icon(
                          Icons.lock_reset,
                          size: 60,
                          color: Colors.blue,
                        ),
                        SizedBox(height: context.hp(2)),
                        Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: context.fontSize(22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: context.hp(2)),
                        AuthTextField(
                          label: 'Current Password',
                          icon: Icons.lock,
                          obscureText: true,
                          controller: _currentPasswordController,
                        ),
                        SizedBox(height: context.hp(2)),
                        AuthTextField(
                          label: 'New Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          controller: _newPasswordController,
                        ),
                        SizedBox(height: context.hp(2)),
                        AuthTextField(
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          controller: _confirmPasswordController,
                        ),
                        SizedBox(height: context.hp(3)),
                        AuthButton(
                          text: 'Update Password',
                          isLoading: state is ChangePasswordLoading,
                          onPressed: () {
                            // No client-side validation – backend will handle everything
                            _cubit.changePassword(
                              currentPassword: _currentPasswordController.text.trim(),
                              newPassword: _newPasswordController.text.trim(),
                              confirmPassword: _confirmPasswordController.text.trim(),
                            );
                          },
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