import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'jadal_surface.dart';

/// The app's one segmented control.
///
/// The row stretches its children, so each segment fills the track's height
/// and the ink splash and selected pill cover the whole segment rather than
/// hugging the label.
class JadalSegmentedSwitch<T> extends StatelessWidget {
  final List<T> values;
  final T active;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final IconData? Function(T)? iconOf;
  final Color accent;

  /// Material's minimum touch target. The old controls were 42–44.
  static const double trackHeight = 48;
  static const double _trackPadding = 4;

  const JadalSegmentedSwitch({
    super.key,
    required this.values,
    required this.active,
    required this.onChanged,
    required this.labelOf,
    this.iconOf,
    this.accent = JadalColors.primaryOrange,
  });

  @override
  Widget build(BuildContext context) {
    final dark = jadalIsDark(context);
    return Container(
      height: trackHeight,
      padding: const EdgeInsets.all(_trackPadding),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        // The fix: segments fill the track's height instead of their text's.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final value in values)
            Expanded(
              child: _Segment(
                label: labelOf(value),
                icon: iconOf?.call(value),
                selected: value == active,
                accent: accent,
                onTap: () => onChanged(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = jadalIsDark(context);
    final radius = BorderRadius.circular(12);
    final selectedColor = jadalTextPrimary(context);
    final mutedColor = jadalTextSecondary(context).withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? accent.withValues(alpha: dark ? 0.24 : 0.16)
            : Colors.transparent,
        borderRadius: radius,
        border: Border.all(
          color: selected ? accent.withValues(alpha: 0.35) : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          splashColor: accent.withValues(alpha: 0.18),
          highlightColor: accent.withValues(alpha: 0.10),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 17,
                        color: selected ? selectedColor : mutedColor,
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      label,
                      maxLines: 1,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected ? selectedColor : mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
