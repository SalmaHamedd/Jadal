import 'package:flutter/material.dart';
import 'package:jadal_app/core/colors.dart';

class ProfileActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const ProfileActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryblue,
        side: BorderSide(color: AppColors.primaryblue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}