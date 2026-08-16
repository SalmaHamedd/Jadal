import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../theme/app_text_styles.dart';

/// Styled dialog shell used across the live-debate feature.
/// Mirrors the `CustomDialog(width, height, firstColor, secondColor, bodyColor,
/// title, body)` contract the legacy `call` feature referenced (that file does
/// not exist in this project), re-skinned with the Jadal palette. The header is
/// a [firstColor]→[secondColor] gradient; the body sits on [bodyColor].
class JadalDialog extends StatelessWidget {
  final double width;
  final double height;
  final Color firstColor;
  final Color secondColor;
  final Color bodyColor;
  final String title;
  final Widget body;
  final bool showClose;

  /// Optional leading glyph shown in a soft chip — gives the header a purpose
  /// instead of a bare colour band.
  final IconData? icon;

  const JadalDialog({
    super.key,
    required this.width,
    required this.height,
    required this.firstColor,
    required this.secondColor,
    required this.bodyColor,
    required this.title,
    required this.body,
    this.showClose = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // No gradient — the old blue→orange band read as garish. A calm header that
    // sits on the body surface with a single coloured accent (icon chip + a thin
    // accent rule) reads far more elegant on a small dialog. [secondColor] is kept
    // only for a faint accent tint; the header is otherwise the body colour.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark ? Colors.white : const Color(0xFF1A3868);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widgetBorderRadius + 8),
        child: Container(
          width: width,
          height: height,
          color: bodyColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 10, 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: firstColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon ?? Icons.info_outline_rounded,
                          color: firstColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title(context)
                            .copyWith(color: titleColor, letterSpacing: 0.2),
                      ),
                    ),
                    if (showClose)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.close_rounded,
                            color: titleColor.withValues(alpha: 0.6), size: 20),
                      ),
                  ],
                ),
              ),
              // A slim two-tone accent rule — a light brand touch under the header
              // instead of a heavy gradient band.
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      firstColor.withValues(alpha: 0.55),
                      secondColor.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
