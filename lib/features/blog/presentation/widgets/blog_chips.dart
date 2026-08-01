import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/blog/domain/entities/category.dart';
import 'package:jadal_app/features/blog/domain/entities/tag.dart';

/// Categories (filled) + tags (outline) for a blog — same filled/outline
/// convention already used for `motion.frameworks` vs `motion.tags`
/// elsewhere in the app. Renders nothing if both lists are empty.
class BlogChips extends StatelessWidget {
  final List<Category> categories;
  final List<Tag> tags;
  const BlogChips({super.key, required this.categories, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final c in categories) _BlogChip(label: c.name, filled: true),
        for (final t in tags) _BlogChip(label: t.name, filled: false),
      ],
    );
  }
}

class _BlogChip extends StatelessWidget {
  final String label;
  final bool filled;
  const _BlogChip({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    final color = JadalColors.primaryOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: filled ? 0.5 : 0.7)),
      ),
      child: Text(
        label,
        style: AppTextStyles.small(context).copyWith(fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
