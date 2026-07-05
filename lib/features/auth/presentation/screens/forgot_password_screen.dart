import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/features/auth/presentation/screens/reset_password_screen.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../cubit/forgot_password_cubit.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? true)) return;
    context.read<ForgotPasswordCubit>().forgotPassword(
      _emailController.text.trim(),
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

    final cardBg = isDark
        ? JadalColors.darkBackground
        : JadalColors.lightSurface;
    final textPrimary = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.deepBlue;
    final textSecondary = isDark
        ? JadalColors.darkTextSecondary
        : JadalColors.lightTextSecondary;
    final iconColor = isDark
        ? const Color(0xFFF59A4A)
        : JadalColors.primaryBlue;
    final accentLink = isDark
        ? const Color(0xFFF59A4A)
        : JadalColors.primaryOrange;

    final iconCircle = isMobile ? 60.0 : 72.0;

    // Blob-free: the shared JadalGradientBackground is the whole backdrop, the
    // same as the rest of the app.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JadalGradientBackground(
        child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth >= 600
                    ? 460.0
                    : double.infinity;
                return Center(
                  child: SingleChildScrollView(
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
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: textSecondary,
                                    ),
                                    icon: Icon(
                                      Icons.arrow_back_rounded,
                                      size: 18,
                                      color: textSecondary,
                                    ),
                                    label: Text(
                                      loc.backToLogin,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: context.fontSize(
                                          13,
                                          min: 11.5,
                                          max: 13,
                                        ),
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 16 : 22),
                                Center(
                                  child: Container(
                                    width: iconCircle,
                                    height: iconCircle,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          JadalColors.primaryBlue.withValues(
                                            alpha: 0.18,
                                          ),
                                          JadalColors.primaryOrange.withValues(
                                            alpha: 0.18,
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.lock_reset_rounded,
                                      size: isMobile ? 28 : 34,
                                      color: iconColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 16 : 20),
                                Text(
                                  loc.forgotPasswordTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: context.fontSize(
                                      19,
                                      min: 16,
                                      max: 22,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  loc.forgotPasswordSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: context.fontSize(
                                      13,
                                      min: 11.5,
                                      max: 14,
                                    ),
                                    color: textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 22 : 28),
                                AuthTextField(
                                  label: loc.email,
                                  icon: Icons.email_outlined,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                ),
                                SizedBox(height: isMobile ? 20 : 24),
                                BlocConsumer<
                                  ForgotPasswordCubit,
                                  ForgotPasswordState
                                >(
                                  listener: (context, state) {
                                    if (state is ForgotPasswordFailure) {
                                      JadalSnackBar.show(
                                        context,
                                        state.message,
                                        type: SnackBarType.error,
                                      );
                                    }
                                    if (state is ForgotPasswordSuccess) {
                                      showDialog<void>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(loc.checkYourEmail),
                                          content: Text(state.message),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ResetPasswordScreen(
                                                          email:
                                                              _emailController
                                                                  .text
                                                                  .trim(),
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Text(loc.ok),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  builder: (context, state) => AuthButton(
                                    text: loc.forgotPasswordButton,
                                    isLoading: state is ForgotPasswordLoading,
                                    onPressed: _submit,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      loc.backToLogin,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: context.fontSize(
                                          13,
                                          min: 12,
                                          max: 14,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color: accentLink,
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
                  ),
                );
              },
            ),
        ),
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
