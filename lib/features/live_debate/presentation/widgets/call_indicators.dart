import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Mic badge for a video card. Two states with the **same footprint** so
/// the badge never shifts when the mic toggles:
/// • mic ON → a smooth volume-reactive bars visualizer (the "dots & lines"
/// look) driven by the participant's live audio level;
/// • mic OFF → a calm dark-red mic-off badge (not the eye-searing bright red).
class MicVolumeIndicator extends StatefulWidget {
  final bool micOn;
  final bool isSpeaking;
  final double scale;
  final Color activeColor;

  /// Returns the current 0..1 audio level. Polled while the mic is on.
  final double Function()? levelProvider;

  const MicVolumeIndicator({
    super.key,
    required this.micOn,
    this.isSpeaking = false,
    this.scale = 1,
    this.activeColor = JadalColors.primaryBlue,
    this.levelProvider,
  });

  @override
  State<MicVolumeIndicator> createState() => _MicVolumeIndicatorState();
}

class _MicVolumeIndicatorState extends State<MicVolumeIndicator> {
  static const _weights = [0.55, 1.0, 0.78, 0.42];
  Timer? _timer;
  double _level = 0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant MicVolumeIndicator old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.micOn && _timer == null) {
      // ~11fps is plenty for a volume meter and cheap to repaint.
      _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
        if (!mounted) return;
        final raw = widget.levelProvider?.call() ?? 0;
        // Keep the meter alive while speaking even if level reporting is flaky.
        final target = math.max(raw, widget.isSpeaking ? 0.4 : 0.0).clamp(0.0, 1.0);
        setState(() => _level += (target - _level) * 0.5);
      });
    } else if (!widget.micOn && _timer != null) {
      _timer!.cancel();
      _timer = null;
      _level = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return SizedBox(
      width: 32 * s,
      height: 22 * s,
      child: Center(
        child: widget.micOn ? _bars(s) : _muted(s),
      ),
    );
  }

  Widget _bars(double s) => Container(
        padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 3 * s),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8 * s),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < _weights.length; i++) ...[
              if (i > 0) SizedBox(width: 1.6 * s),
              _bar(i, s),
            ],
          ],
        ),
      );

  Widget _bar(int i, double s) {
    final maxH = 12.0 * s;
    final minH = 2.5 * s;
    final h = (minH + (maxH - minH) * (_level * _weights[i])).clamp(minH, maxH);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: 2.6 * s,
      height: h,
      decoration: BoxDecoration(
        color: widget.activeColor,
        borderRadius: BorderRadius.circular(2 * s),
      ),
    );
  }

  Widget _muted(double s) => Container(
        width: 20 * s,
        height: 20 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkRed.withValues(alpha: 0.20),
          border: Border.all(color: AppColors.darkRed, width: 1 * s),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.mic_off_rounded, color: AppColors.darkRed, size: 12 * s),
      );
}
