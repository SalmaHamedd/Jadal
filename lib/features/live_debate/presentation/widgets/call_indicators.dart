import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Small "muted" badge shown on a video card (recolored from the legacy
/// `CustomMuteIndicator`). [scale] is the card's short side / 168.
class MuteIndicator extends StatelessWidget {
  final double scale;
  final Color color;
  const MuteIndicator({super.key, this.scale = 1, this.color = const Color(0xFFE53935)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 0.8 * scale),
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
      ),
      padding: EdgeInsets.all(4 * scale),
      child: Icon(Icons.mic_off_rounded, color: color, size: 16 * scale),
    );
  }
}

/// Animated "speaking" ring (recolored from the legacy
/// `CustomSpeakingIndicator`).
class SpeakingIndicator extends StatelessWidget {
  final bool isSpeaking;
  final double scale;
  final Color activeColor;
  final Color inactiveColor;

  const SpeakingIndicator({
    super.key,
    required this.isSpeaking,
    this.scale = 1,
    this.activeColor = JadalColors.primaryBlue,
    this.inactiveColor = JadalColors.judgesGrey,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSpeaking ? activeColor : Colors.transparent,
          width: 2.4 * scale,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSpeaking ? activeColor : inactiveColor,
            width: 0.8 * scale,
          ),
        ),
        padding: EdgeInsets.all(4 * scale),
        child: Icon(
          Icons.mic_rounded,
          color: isSpeaking ? activeColor : inactiveColor,
          size: 16 * scale,
        ),
      ),
    );
  }
}
