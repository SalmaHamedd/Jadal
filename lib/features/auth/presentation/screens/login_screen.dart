import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/colors.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/services/message_service.dart';
import 'package:jadal_app/features/auth/data/repositories/auth_repository.dart';
import 'package:jadal_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:jadal_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_card.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_gradient_background.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jadal_app/features/profile/presentation/screens/profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LoginCubit _loginCubit;

  @override
  void initState() {
    super.initState();
    final repository = AuthRepository();
    _loginCubit = LoginCubit(repository);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loginCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final maxCardWidth = isTablet ? 500.0 : 450.0;

    return Scaffold(
      body: AuthGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/Jadal-logo.jpg',
                      height: context.hp(12),
                    ),
                  ),
                  SizedBox(height: context.hp(2)),
                  Text(
                    'Jadal',
                    style: TextStyle(
                      fontSize: context.fontSize(25, max: 36),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'School Debates Platform',
                    style: TextStyle(
                      fontSize: context.fontSize(15, max: 18),
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(context.wp(6)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCardWidth),
                      child: AuthCard(
                        child: BlocConsumer<LoginCubit, LoginState>(
                          bloc: _loginCubit,
                          listener: (context, state) {
                            if (state is LoginSuccess) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            }
                            if (state is LoginFailure) {
                              MessageService.showError(context, state.message);
                            }
                          },
                          builder: (context, state) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: context.fontSize(22, max: 28),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: context.hp(2)),
                                AuthTextField(
                                  label: 'Email',
                                  icon: Icons.email,
                                  controller: _emailController,
                                ),
                                SizedBox(height: context.hp(1)),
                                AuthTextField(
                                  label: 'Password',
                                  icon: Icons.lock,
                                  obscureText: true,
                                  controller: _passwordController,
                                ),
                                SizedBox(height: context.hp(2)),
                                AuthButton(
                                  text: 'Log In',
                                  isLoading: state is LoginLoading,
                                  onPressed: () {
                                    _loginCubit.login(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );
                                  },
                                ),
                                SizedBox(height: context.hp(1.5)),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot Password?',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
