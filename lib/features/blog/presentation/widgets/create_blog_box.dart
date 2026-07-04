import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';

class CreateBlogBox extends StatelessWidget {
  final VoidCallback onTap;

  const CreateBlogBox({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: context.hp(1.5)),
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(1.5),
      ),
      decoration: BoxDecoration(
        color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: context.wp(4),
              backgroundColor: JadalColors.primaryOrange,
              child: const Icon(Icons.edit, color: Colors.white, size: 22),
            ),
            SizedBox(width: context.wp(3)),
            Expanded(
              child: Text(
                'ماذا تريد أن تكتب؟ انشر مقالاً جديداً...',
                style: TextStyle(
                  color: isDark
                      ? JadalColors.darkTextSecondary
                      : Colors.grey[600],
                  fontSize: context.fontSize(15),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? JadalColors.darkTextSecondary : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
