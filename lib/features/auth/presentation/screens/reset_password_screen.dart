import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../cubit/reset_password_cubit.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import 'login_screen.dart';
import '../../data/repositories/auth_repository.dart'; // or mock

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final ResetPasswordCubit _cubit;   // ✅ declared

  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final repository = ApiAuthRepository(); // or MockAuthRepository()
    _cubit = ResetPasswordCubit(repository);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _cubit.close();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? true)) return;
    context.read<ResetPasswordCubit>().resetPassword(
      email: widget.email,
      token: _tokenController.text.trim(),
      password: _passwordController.text.trim(),
      passwordConfirmation: _confirmController.text.trim(),
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

    final scaffoldBg = isDark ? JadalColors.darkSurface : JadalColors.lightBackground;
    final cardBg = isDark ? JadalColors.darkBackground : JadalColors.lightSurface;
    final textPrimary = isDark ? JadalColors.darkTextPrimary : JadalColors.deepBlue;
    final textSecondary = isDark ? JadalColors.darkTextSecondary : JadalColors.lightTextSecondary;
    final accentLink = isDark ? const Color(0xFFF59A4A) : JadalColors.primaryOrange;

    final blobSize = isMobile ? 220.0 : 280.0;
    final logoSize = isMobile ? 65.0 : 80.0;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Blur blobs (identical to LoginScreen)
            Positioned(
              top: 160,
              left: -30,
              child: _blurBlob(
                color: isDark ? JadalColors.primaryOrange.withAlpha(26) : JadalColors.primaryBlue.withAlpha(36),
                size: blobSize,
              ),
            ),
            Positioned(
              top: 520,
              right: -130,
              child: _blurBlob(
                color: isDark ? JadalColors.primaryOrange.withAlpha(26) : JadalColors.primaryBlue.withAlpha(36),
                size: blobSize,
              ),
            ),
            Positioned(
              top: -120,
              right: -70,
              child: _blurBlob(
                color: isDark ? JadalColors.primaryOrange.withAlpha(26) : JadalColors.primaryBlue.withAlpha(36),
                size: blobSize,
              ),
            ),
            Positioned(
              top: 770,
              left: -80,
              child: _blurBlob(
                color: isDark ? JadalColors.primaryOrange.withAlpha(26) : JadalColors.primaryBlue.withAlpha(36),
                size: blobSize,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth >= 600 ? 460.0 : double.infinity;
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: size.height * (isMobile ? 0.04 : 0.06),
                        bottom: 24 + mq.viewInsets.bottom,
                      ),
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
                                      fontSize: context.fontSize(24, min: 18, max: 26),
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 18 : 22),
                                Text(
                                  loc.resetPasswordTitle,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: context.fontSize(19, min: 14, max: 22),
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  loc.resetPasswordSubtitle,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: context.fontSize(13, min: 10.5, max: 14),
                                    color: textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 20 : 26),
                                AuthTextField(
                                  label: loc.resetCode,
                                  icon: Icons.pin_outlined,
                                  controller: _tokenController,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                                ),
                                const SizedBox(height: 16),
                                BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                                  buildWhen: (prev, curr) =>
                                      curr is ResetPasswordVisibility || curr is ResetPasswordInitial,
                                  builder: (context, state) {
                                    final cubit = context.read<ResetPasswordCubit>();
                                    return AuthTextField(
                                      label: loc.newPassword,
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscureText: cubit.obscurePassword,
                                      onToggleVisibility: cubit.togglePasswordVisibility,
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) => _confirmFocus.requestFocus(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
                                  buildWhen: (prev, curr) =>
                                      curr is ResetPasswordVisibility || curr is ResetPasswordInitial,
                                  builder: (context, state) {
                                    final cubit = context.read<ResetPasswordCubit>();
                                    return AuthTextField(
                                      label: loc.confirmPassword,
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscureText: cubit.obscureConfirmPassword,
                                      onToggleVisibility: cubit.toggleConfirmPasswordVisibility,
                                      controller: _confirmController,
                                      focusNode: _confirmFocus,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _submit(),
                                    );
                                  },
                                ),
                                SizedBox(height: isMobile ? 18 : 22),
                                BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
                                  listenWhen: (prev, curr) =>
                                      curr is ResetPasswordFailure || curr is ResetPasswordSuccess,
                                  listener: (context, state) {
                                    if (state is ResetPasswordFailure) {
                                      JadalSnackBar.show(
                                        context,
                                        state.message,
                                        type: SnackBarType.warning,
                                      );
                                    }
                                    if (state is ResetPasswordSuccess) {
                                      JadalSnackBar.show(
                                        context,
                                        state.message,
                                        type: SnackBarType.success,
                                      );
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      );
                                    }
                                  },
                                  buildWhen: (prev, curr) =>
                                      curr is ResetPasswordLoading ||
                                      curr is ResetPasswordFailure ||
                                      curr is ResetPasswordSuccess ||
                                      curr is ResetPasswordInitial,
                                  builder: (context, state) => AuthButton(
                                    text: loc.resetPasswordButton,
                                    isLoading: state is ResetPasswordLoading,
                                    onPressed: _submit,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    loc.backToLogin,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: context.fontSize(12, min: 10, max: 14),
                                      color: accentLink,
                                      fontWeight: FontWeight.w600,
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
                },
              ),
            ),
          ],
        ),
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
  const _FloatingCard({required this.isDark, required this.cardBg, required this.child});

  @override
  Widget build(BuildContext context) {
    final pad = context.isMobile ? 18.0 : 24.0;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 97 : 20),
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