import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

enum SnackBarType { error, warning, success }

class JadalSnackBar {
  JadalSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color accent;
    final Color bgDark;
    final Color bgLight;
    final IconData icon;

    switch (type) {
      case SnackBarType.error:
        accent = const Color(0xFFE53935);
        bgDark = const Color(0xFF2C1515);
        bgLight = const Color(0xFFFFD6D6);
        icon = Icons.error_outline_rounded;
      case SnackBarType.warning:
        accent = const Color(0xFFF59A4A);
        bgDark = const Color(0xFF2C1E0E);
        bgLight = const Color(0xFFFAE8CE);
        icon = Icons.warning_amber_rounded;
      case SnackBarType.success:
        accent = const Color(0xFF4AA8F5);
        bgDark = const Color(0xFF0E1E2C);
        bgLight = const Color(0xFFDDF0FF);
        icon = Icons.check_circle_outline_rounded;
    }

    final bg = isDark ? bgDark : bgLight;
    final textColor = isDark ? Colors.white.withValues(alpha: 0.90) : const Color(0xFF1A2030);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.zero,
          duration: duration,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: BorderDirectional(start: BorderSide(color: accent, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.body(context)
                        .copyWith(fontWeight: FontWeight.w500, color: textColor, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
