import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One tab for [JadalBottomNavBar].
class JadalNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const JadalNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A custom bottom nav bar (§5) replacing the stock `BottomNavigationBar`,
/// which had no room for a selected-state animation and gave every tab a
/// full-tile ripple. This one floats a translucent, rounded surface over the
/// shared [JadalGradientBackground] instead of painting an opaque strip, so
/// the gradient reads as one continuous wash instead of being cropped, and
/// slides a soft pill behind the selected icon instead of just recoloring it.
class JadalBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<JadalNavItem> items;
  final ValueChanged<int> onTap;

  const JadalBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: (isDark ? JadalColors.darkSurface : JadalColors.lightSurface)
                .withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / items.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * currentIndex,
                      top: 8,
                      bottom: 8,
                      width: itemWidth,
                      child: Center(
                        child: Container(
                          width: (itemWidth - 22).clamp(0, itemWidth),
                          height: 44,
                          decoration: BoxDecoration(
                            color: JadalColors.primaryOrange.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: JadalColors.primaryOrange.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _NavTapTarget(
                              item: items[i],
                              selected: i == currentIndex,
                              onTap: () => onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTapTarget extends StatelessWidget {
  final JadalNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTapTarget({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? JadalColors.primaryOrange : JadalColors.judgesGrey;
    // The ink surface is sized to EXACTLY the sliding pill's rect
    // (itemWidth − 22 wide × 44 tall, centered — see the Stack above), so a
    // press shows one highlight shape, not a second, larger rounded rect
    // superimposed on the pill. The outer GestureDetector keeps the whole
    // cell tappable without painting any ink of its own; when the tap lands
    // on the ink area the InkWell's recognizer wins the gesture arena.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        child: Center(
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: selected ? 1.08 : 1.0,
                      curve: Curves.easeOut,
                      child: Icon(selected ? item.activeIcon : item.icon, color: color, size: 23),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: color,
                      ),
                      child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
