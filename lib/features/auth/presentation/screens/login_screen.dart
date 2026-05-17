import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/colors.dart';
import 'package:jadal_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:jadal_app/features/auth/data/repositories/auth_repository.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth-text-field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.deepblue, AppColors.warmorange],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/Jadal-logo.jpg',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Jadal",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "School Debates Platform",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      color: AppColors.lightbackground,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: BlocConsumer<LoginCubit, LoginState>(
                          bloc: _loginCubit,
                          listener: (context, state) {
                            if (state is LoginSuccess) {
                              // ✅ TEST: Show dialog instead of navigating
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('✅ Login Success'),
                                  content: Text('User ID: ${state.userId}\nWelcome!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } else if (state is LoginFailure) {
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
                                const Text('Log in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      AuthTextField(
                                        label: 'Email',
                                        controller: _emailController,
                                        validator: (value) =>
                                            (value == null || !value.contains('@')) ? 'Invalid email' : null,
                                      ),
                                      const SizedBox(height: 14),
                                      AuthTextField(
                                        label: 'Password',
                                        obscureText: true,
                                        controller: _passwordController,
                                        validator: (value) =>
                                            (value == null || value.length < 6) ? 'Password too short' : null,
                                      ),
                                      const SizedBox(height: 14),
                                      ElevatedButton(
                                        onPressed: state is LoginLoading
                                            ? null
                                            : () {
                                                if (_formKey.currentState!.validate()) {
                                                  _loginCubit.login(
                                                    _emailController.text.trim(),
                                                    _passwordController.text.trim(),
                                                  );
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryblue,
                                          minimumSize: const Size.fromHeight(50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: state is LoginLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text("Log In", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
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