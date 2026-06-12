import 'package:flutter/material.dart';
import 'package:jadal_app/core/colors.dart';

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
          ? Icon(icon, size: 18, color: textColor ?? AppColors.primaryblue)
          : const SizedBox.shrink(),
      label: Text(
        text,
        style: TextStyle(color: textColor ?? AppColors.primaryblue),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: borderColor ?? AppColors.primaryblue,
        side: BorderSide(color: borderColor ?? AppColors.primaryblue),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
