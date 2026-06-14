import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/features/main/presentation/screens/main_screen.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../cubit/login_cubit.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form plumbing only. No business logic lives here.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? true)) return;
    context.read<LoginCubit>().login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = context.loc;
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final isMobile = context.isMobile;

    final scaffoldBg = isDark
        ? JadalColors.darkSurface
        : JadalColors.lightBackground;
    final cardBg = isDark
        ? JadalColors.darkBackground
        : JadalColors.lightSurface;
    final textPrimary = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.deepBlue;
    final textSecondary = isDark
        ? JadalColors.darkTextSecondary
        : JadalColors.lightTextSecondary;
    final accentLink = isDark
        ? const Color(0xFFF59A4A)
        : JadalColors.primaryOrange;

    final blobSize = isMobile ? 220.0 : 280.0;
    final logoSize = isMobile ? 65.0 : 80.0;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 160,
            left: -30,
            child: _blurBlob(
              color: isDark
                  ? JadalColors.primaryOrange.withValues(alpha: 0.105)
                  : JadalColors.primaryBlue.withValues(alpha: 0.14),
              size: blobSize,
            ),
          ),
          Positioned(
            top: 520,
            right: -130,
            child: _blurBlob(
              color: isDark
                  ? JadalColors.primaryOrange.withValues(alpha: 0.105)
                  : JadalColors.primaryBlue.withValues(alpha: 0.14),
              size: blobSize,
            ),
          ),
          Positioned(
            top: -120,
            right: -70,
            child: _blurBlob(
              color: isDark
                  ? JadalColors.primaryOrange.withValues(alpha: 0.105)
                  : JadalColors.primaryBlue.withValues(alpha: 0.14),
              size: blobSize,
            ),
          ),
          Positioned(
            top: 770,
            left: -80,
            child: _blurBlob(
              color: isDark
                  ? JadalColors.primaryOrange.withValues(alpha: 0.105)
                  : JadalColors.primaryBlue.withValues(alpha: 0.14),
              size: blobSize,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth >= 600
                    ? 460.0
                    : double.infinity;
                return Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: size.height * (isMobile ? 0.04 : 0.06),
                      bottom: 24 + mq.viewInsets.bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: _FloatingCard(
                          isDark: isDark,
                          cardBg: cardBg,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'assets/images/Jadal-logo.jpg',
                                      width: logoSize,
                                      height: logoSize,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 6 : 12),
                                Center(
                                  child: Text(
                                    loc.appName,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: context.fontSize(
                                        24,
                                        min: 18,
                                        max: 26,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 18 : 22),
                                Text(
                                  loc.loginWelcome,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: context.fontSize(
                                      19,
                                      min: 14,
                                      max: 22,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  loc.loginSubtitle,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: context.fontSize(
                                      13,
                                      min: 10.5,
                                      max: 14,
                                    ),
                                    color: textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 20 : 26),
                                AuthTextField(
                                  label: loc.email,
                                  icon: Icons.email_outlined,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      _passwordFocus.requestFocus(),
                                ),
                                const SizedBox(height: 16),
                                // Password field reacts to the cubit's visibility state.
                                BlocBuilder<LoginCubit, LoginState>(
                                  buildWhen: (prev, curr) =>
                                      curr is LoginPasswordVisibility ||
                                      curr is LoginInitial,
                                  builder: (context, state) {
                                    final cubit = context.read<LoginCubit>();
                                    return AuthTextField(
                                      label: loc.password,
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscureText: cubit.obscurePassword,
                                      onToggleVisibility:
                                          cubit.togglePasswordVisibility,
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _submit(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      loc.forgetPassword,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: context.fontSize(
                                          10,
                                          min: 7.5,
                                          max: 14,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color: accentLink,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 18 : 22),
                                BlocConsumer<LoginCubit, LoginState>(
                                  listenWhen: (prev, curr) =>
                                      curr is LoginFailure ||
                                      curr is LoginSuccess,
                                  listener: (context, state) {
                                    if (state is LoginFailure) {
                                      JadalSnackBar.show(
                                        context,
                                        state.message,
                                        type: SnackBarType.warning,
                                      );
                                    }
                                    if (state is LoginSuccess) {
                                      // Clear all previous routes and navigate to MainScreen
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MainScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  },
                                  buildWhen: (prev, curr) =>
                                      curr is LoginLoading ||
                                      curr is LoginFailure ||
                                      curr is LoginSuccess ||
                                      curr is LoginInitial,
                                  builder: (context, state) => AuthButton(
                                    text: loc.loginButton,
                                    isLoading: state is LoginLoading,
                                    onPressed: _submit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurBlob({required Color color, required double size}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Widget child;

  const _FloatingCard({
    required this.isDark,
    required this.cardBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final pad = context.isMobile ? 18.0 : 24.0;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
            blurRadius: isDark ? 36 : 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.all(pad),
      child: child,
    );
  }
}
