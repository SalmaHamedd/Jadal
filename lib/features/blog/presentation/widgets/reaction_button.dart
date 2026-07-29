import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';

/// A tappable like/dislike pill. No loading spinner — the underlying cubit
/// already applies the count/color change optimistically before the network
/// call resolves, so the tap just needs to *feel* instant: a quick icon pop
/// plus a color crossfade, the way Facebook's reaction buttons do it. A
/// failed request is rolled back (and reported) by the cubit, not this
/// widget, so it never needs to show an in-flight state.
class ReactionButton extends StatefulWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final VoidCallback onPressed;
  final Color? activeColor;

  const ReactionButton({
    super.key,
    required this.icon,
    required this.count,
    required this.isActive,
    required this.onPressed,
    this.activeColor,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  double _scale = 1.0;

  @override
  void didUpdateWidget(covariant ReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      setState(() => _scale = 1.35);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _scale = 1.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isActive ? (widget.activeColor ?? JadalColors.primaryOrange) : JadalColors.judgesGrey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: widget.isActive ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(widget.icon, key: ValueKey(widget.isActive), size: 16, color: color),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                child: Text('${widget.count}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
