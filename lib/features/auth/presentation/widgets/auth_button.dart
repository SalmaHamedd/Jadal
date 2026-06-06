import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/responsive_extension.dart';

class AuthButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  double _scale = 1.0;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  void _setPressed(bool pressed) {
    if (_isDisabled) return;
    setState(() => _scale = pressed ? 0.97 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final height = isMobile ? 44.0 : 52.0;
    final spinner = isMobile ? 16.0 : 22.0;
    final fontSize = context.fontSize(13.5, min: 11, max: 16);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _isDisabled
                ? null
                : const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [JadalColors.primaryBlue, JadalColors.primaryOrange],
            ),
            color: _isDisabled
                ? JadalColors.primaryOrange.withValues(alpha: 0.38)
                : null,
            borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
            boxShadow: _isDisabled
                ? null
                : [
              BoxShadow(
                color: JadalColors.primaryBlue.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
            height: spinner,
            width: spinner,
            child: const CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          )
              : Text(
            widget.text,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}