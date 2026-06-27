import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A lightweight, **dependency-free** confetti burst for the result reveal (§10).
/// Spawns a fixed set of particles that fall + drift + spin, then fades and
/// calls [onComplete]. Non-interactive (wrapped in [IgnorePointer]) so it never
/// blocks the result UI underneath.
class ConfettiOverlay extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    this.duration = const Duration(milliseconds: 2600),
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const List<Color> _colors = [
    JadalColors.primaryBlue,
    JadalColors.primaryOrange,
    Color(0xFFF5C542), // gold
    Color(0xFF2E9E5B), // green
    Color(0xFFFFFFFF), // white
    Color(0xFFE36EA4), // pink
  ];

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _particles = List.generate(90, (i) => _Particle.random(rnd, _colors));
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete?.call();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_particles, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  final double xFraction; // start x (0..1 of width)
  final double startYFraction; // start y (slightly above the top)
  final double fallSpeed; // how far down it travels (fraction of height)
  final double drift; // horizontal drift over the animation
  final double sway; // sinusoidal sway amplitude
  final double swayPhase;
  final double rotationTurns;
  final double startRotation;
  final double width;
  final double height;
  final Color color;

  const _Particle({
    required this.xFraction,
    required this.startYFraction,
    required this.fallSpeed,
    required this.drift,
    required this.sway,
    required this.swayPhase,
    required this.rotationTurns,
    required this.startRotation,
    required this.width,
    required this.height,
    required this.color,
  });

  factory _Particle.random(Random rnd, List<Color> colors) => _Particle(
        xFraction: rnd.nextDouble(),
        startYFraction: -0.15 - rnd.nextDouble() * 0.35,
        fallSpeed: 0.9 + rnd.nextDouble() * 0.5,
        drift: (rnd.nextDouble() - 0.5) * 0.3,
        sway: 0.01 + rnd.nextDouble() * 0.04,
        swayPhase: rnd.nextDouble() * pi * 2,
        rotationTurns: 1 + rnd.nextDouble() * 3,
        startRotation: rnd.nextDouble() * pi * 2,
        width: 6 + rnd.nextDouble() * 7,
        height: 9 + rnd.nextDouble() * 8,
        color: colors[rnd.nextInt(colors.length)],
      );
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1

  const _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Fade out over the final quarter of the animation.
    final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final y = (p.startYFraction + p.fallSpeed * t) * size.height;
      if (y < -p.height || y > size.height + p.height) continue;
      final x = (p.xFraction + p.drift * t) * size.width +
          sin(p.swayPhase + t * pi * 6) * (p.sway * size.width);
      final rotation = p.startRotation + p.rotationTurns * pi * 2 * t;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      paint.color = p.color.withValues(alpha: fade);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.width, height: p.height),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
