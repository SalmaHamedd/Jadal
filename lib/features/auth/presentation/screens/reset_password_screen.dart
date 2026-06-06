import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/colors.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/services/message_service.dart';
import 'package:jadal_app/features/auth/data/repositories/auth_repository.dart';
import 'package:jadal_app/features/auth/presentation/cubit/reset_password_cubit.dart';
import 'package:jadal_app/features/auth/presentation/screens/login_screen.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_card.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_gradient_background.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _tokenController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final ResetPasswordCubit _cubit;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    final repository = AuthRepository();
    _cubit = ResetPasswordCubit(repository);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final maxCardWidth = isTablet ? 500.0 : 450.0;

    return Scaffold(
      body: AuthGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: isTablet ? 28 : 24,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(context.wp(6)),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxCardWidth),
                        child: AuthCard(
                          child:
                              BlocConsumer<
                                ResetPasswordCubit,
                                ResetPasswordState
                              >(
                                bloc: _cubit,
                                listener: (context, state) {
                                  if (state is ResetPasswordSuccess) {
                                    MessageService.showSuccess(
                                      context,
                                      state.message,
                                    );
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',
                                      (route) => false,
                                    );
                                  } else if (state is ResetPasswordFailure) {
                                    MessageService.showError(
                                      context,
                                      state.message,
                                    );
                                  }
                                },
                                builder: (context, state) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_reset,
                                        size: isTablet ? 80 : 60,
                                        color: AppColors.primaryblue,
                                      ),
                                      SizedBox(height: context.hp(2)),
                                      Text(
                                        'Reset Password',
                                        style: TextStyle(
                                          fontSize: context.fontSize(
                                            22,
                                            max: 32,
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: context.hp(1)),
                                      Text(
                                        'Enter the code sent to your email and your new password.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: context.fontSize(
                                            14,
                                            max: 18,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: context.hp(2)),
                                      AuthTextField(
                                        label: 'Reset Code',
                                        icon: Icons.pin,
                                        controller: _tokenController,
                                      ),
                                      SizedBox(height: context.hp(2)),
                                      AuthTextField(
                                        label: 'New Password',
                                        icon: Icons.lock,
                                        obscureText: true,
                                        controller: _passwordController,
                                      ),
                                      SizedBox(height: context.hp(2)),
                                      AuthTextField(
                                        label: 'Confirm Password',
                                        icon: Icons.lock_outline,
                                        obscureText: true,
                                        controller: _confirmPasswordController,
                                      ),
                                      SizedBox(height: context.hp(2)),
                                      AuthButton(
                                        text: 'Reset Password',
                                        isLoading:
                                            state is ResetPasswordLoading,
                                        onPressed: () {
                                          _cubit.resetPassword(
                                            email: widget.email,
                                            token: _tokenController.text.trim(),
                                            password: _passwordController.text
                                                .trim(),
                                            passwordConfirmation:
                                                _confirmPasswordController.text
                                                    .trim(),
                                          );
                                        },
                                      ),
                                      SizedBox(height: context.hp(1.5)),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          'Back to Login',
                                          style: TextStyle(
                                            color: AppColors.primaryblue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
