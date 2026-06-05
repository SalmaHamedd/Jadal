import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/colors.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/services/message_service.dart';
import 'package:jadal_app/features/auth/data/repositories/auth_repository.dart';
import 'package:jadal_app/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_card.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_gradient_background.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  late final ForgotPasswordCubit _cubit;

  @override
  void initState() {
    super.initState();
    final repository = AuthRepository();
    _cubit = ForgotPasswordCubit(repository);
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                          child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
                            bloc: _cubit,
                            listener: (context, state) {
                              if (state is ForgotPasswordSuccess) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Check Your Email'),
                                    content: Text(state.message),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); 
                                          Navigator.pop(context);
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              if (state is ForgotPasswordFailure) {
                                MessageService.showError(context, state.message);
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
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: context.fontSize(22, max: 32),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: context.hp(1)),
                                  Text(
                                    'We’ll send you a link to reset your password.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: context.fontSize(14, max: 18),
                                    ),
                                  ),
                                  SizedBox(height: context.hp(2)),
                                  AuthTextField(
                                    label: 'Email',
                                    icon: Icons.email,
                                    controller: _emailController,
                                  ),
                                  SizedBox(height: context.hp(2)),
                                  AuthButton(
                                    text: 'Send Reset Link',
                                    isLoading: state is ForgotPasswordLoading,
                                    onPressed: () {
                                      _cubit.forgotPassword(
                                        _emailController.text.trim(),
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