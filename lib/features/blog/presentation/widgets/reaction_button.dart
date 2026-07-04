import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';

class ReactionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? activeColor;
  final Color? inactiveColor;

  const ReactionButton({
    super.key,
    required this.icon,
    required this.count,
    required this.isActive,
    required this.onPressed,
    this.isLoading = false,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? JadalColors.primaryOrange)
        : (inactiveColor ?? JadalColors.judgesGrey);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 20),
          color: color,
          onPressed: isLoading ? null : onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
