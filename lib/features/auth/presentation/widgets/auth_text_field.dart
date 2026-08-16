import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/responsive_extension.dart';

/// Fully controlled auth input built on a standard [TextFormField].
/// - One uniform fill colour (no inner "write here" rectangle), and the fill
/// does NOT change on focus/hover — only the border reacts.
/// - Standard Material floating label.
/// - Stateless: for password fields the obscure value comes from the cubit,
/// and the eye calls [onToggleVisibility] back into the cubit.
class AuthTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final IconData? icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  /// Password fields are controlled by the cubit:
  /// set [isPassword] true, pass the current [obscureText], and wire
  /// [onToggleVisibility] to the cubit's toggle function.
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;

  const AuthTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.validator,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = context.isMobile;

    final accent = isDark ? const Color(0xFFF59A4A) : JadalColors.primaryOrange;
    final borderColor = isDark
        ? const Color(0xFF2A3A55)
        : const Color(0xFFD8DEE7);
    final fill = isDark
        ? JadalColors.darkSurfaceElevated
        : const Color(0xFFF1F4F9);
    final textColor = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.lightTextPrimary;
    final secondary = isDark
        ? JadalColors.darkTextSecondary
        : JadalColors.lightTextSecondary;

    final radius = BorderRadius.circular(isMobile ? 12 : 14);
    final fieldStyle = AppTextStyles.body(context).copyWith(color: textColor);
    final labelStyle = AppTextStyles.caption(
      context,
    ).copyWith(color: secondary);
    final iconSize = isMobile ? 18.0 : 21.0;
    final vPad = isMobile ? 14.0 : 16.0;

    OutlineInputBorder outline(Color c, double w) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: c, width: w),
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword && obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      cursorColor: accent,
      style: fieldStyle,
      decoration: InputDecoration(
        // Uniform fill — identical focused or not. No separate inner box.
        filled: true,
        fillColor: fill,
        labelText: label,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: vPad),
        labelStyle: labelStyle,
        floatingLabelStyle: labelStyle.copyWith(color: accent),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: iconSize, color: secondary),
        suffixIcon: isPassword
            ? IconButton(
                splashRadius: 20,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: iconSize,
                  color: secondary,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        border: outline(borderColor, 1.0),
        enabledBorder: outline(borderColor, 1.0),
        focusedBorder: outline(accent, 1.6),
        errorBorder: outline(theme.colorScheme.error, 1.0),
        focusedErrorBorder: outline(theme.colorScheme.error, 1.6),
      ),
    );
  }
}
