import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DiagonalSplitBackground extends StatelessWidget {
  final Animation<double> animation;

  const DiagonalSplitBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _DiagonalPainter(progress: animation.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _DiagonalPainter extends CustomPainter {
  final double progress;

  _DiagonalPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()..color = JadalColors.primaryBlue;
    final orange = Paint()..color = JadalColors.primaryOrange;

    canvas.drawRect(Offset.zero & size, blue);

    final clamped = progress.clamp(0.0, 1.0);
    final dx = size.width * (0.4 + 0.6 * clamped);
    final dy = size.height * (0.4 + 0.6 * clamped);

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - dx, size.height)
      ..lineTo(size.width, size.height - dy)
      ..close();
    canvas.drawPath(path, orange);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width - dx, size.height),
      Offset(size.width, size.height - dy),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _DiagonalPainter old) =>
      old.progress != progress;
}
