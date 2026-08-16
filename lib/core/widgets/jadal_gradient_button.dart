import 'package:flutter/material.dart';

import '../extensions/responsive_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Primary gradient CTA, ported from the auth `AuthButton` design so the
/// gorgeous blue→orange gradient can be reused across the app.
/// Use this for primary actions only (room Join, dialog confirm). Secondary
/// actions (Cancel, toggles, icon buttons) should NOT use this. Rule of thumb:
/// at most one gradient button visible per surface.
class JadalGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final double? borderRadius;

  const JadalGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<JadalGradientButton> createState() => _JadalGradientButtonState();
}

class _JadalGradientButtonState extends State<JadalGradientButton> {
  double _scale = 1.0;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  void _setPressed(bool pressed) {
    if (_isDisabled) return;
    setState(() => _scale = pressed ? 0.97 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final height = widget.height ?? (isMobile ? 44.0 : 52.0);
    final spinner = isMobile ? 16.0 : 22.0;
    final fontSize = context.fontSize(13.5, min: 11, max: 16);
    final radius = widget.borderRadius ?? (isMobile ? 12.0 : 14.0);

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
          width: widget.width ?? double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
            borderRadius: BorderRadius.circular(radius),
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
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: fontSize + 4),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button(context)
                            .copyWith(color: Colors.white, letterSpacing: 0.3),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
