import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';

class MultiSelectField<T> extends StatelessWidget {
  final String label;
  final List<T> selectedItems;
  final String Function(T) displayName;
  final VoidCallback onTap;

  const MultiSelectField({
    super.key,
    required this.label,
    required this.selectedItems,
    required this.displayName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = context.isMobile;
    final selectedNames = selectedItems.map(displayName).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? JadalColors.darkSurfaceElevated
              : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3A55) : const Color(0xFFD8DEE7),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.category,
              color: isDark ? JadalColors.darkTextSecondary : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedNames.isEmpty ? label : selectedNames.join('، '),
                style: TextStyle(
                  color: selectedNames.isEmpty
                      ? (isDark
                            ? JadalColors.darkTextSecondary
                            : Colors.grey[600])
                      : (isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary),
                  fontSize: context.fontSize(12.5, min: 11.5, max: 15),
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? JadalColors.darkTextSecondary : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
