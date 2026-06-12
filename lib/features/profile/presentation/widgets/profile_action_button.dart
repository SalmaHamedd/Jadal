import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';

class ProfileActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? textColor;
  final Color? borderColor;
  final Color? backgroundColor;

  const ProfileActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null
          ? Icon(icon, size: 18, color: textColor ?? JadalColors.primaryBlue)
          : const SizedBox.shrink(),
      label: Text(
        text,
        style: TextStyle(color: textColor ?? JadalColors.primaryBlue),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: borderColor ?? JadalColors.primaryBlue,
        side: BorderSide(color: borderColor ?? JadalColors.primaryBlue),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}