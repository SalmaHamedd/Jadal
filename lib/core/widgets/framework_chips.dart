import 'package:flutter/material.dart';
import '../app_models/framework.dart';
import '../theme/app_colors.dart';
import '../theme/hex_color.dart';

class FrameworkChips extends StatelessWidget {
  final List<Framework> frameworks;
  const FrameworkChips({super.key, required this.frameworks});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final f in frameworks)
          _Chip(label: f.name, color: colorFromHex(f.colorHex) ?? JadalColors.primaryBlue),
      ],
    );
  }
}

/// A wrap of plain tag chips in a single [color].
class TagChips extends StatelessWidget {
  final List<String> tags;
  final Color color;
  const TagChips({super.key, required this.tags, this.color = JadalColors.primaryOrange});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final t in tags) _Chip(label: t, color: color)],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
