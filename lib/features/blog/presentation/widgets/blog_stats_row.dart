import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/blog/presentation/widgets/reaction_button.dart';

class BlogStatsRow extends StatelessWidget {
  final int views;
  final int likes;
  final int dislikes;
  final String? currentReaction;
  final VoidCallback onLikePressed;
  final VoidCallback onDislikePressed;
  final bool isDark;

  const BlogStatsRow({
    super.key,
    required this.views,
    required this.likes,
    required this.dislikes,
    this.currentReaction,
    required this.onLikePressed,
    required this.onDislikePressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.hp(1),
        horizontal: context.wp(3),
      ),
      decoration: BoxDecoration(
        color: isDark ? JadalColors.darkSurfaceElevated : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: JadalColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: JadalColors.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  '$views',
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: JadalColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              ReactionButton(
                icon: Icons.thumb_up_alt_rounded,
                count: likes,
                isActive: currentReaction == 'like',
                onPressed: onLikePressed,
              ),
              const SizedBox(width: 8),
              ReactionButton(
                icon: Icons.thumb_down_alt_rounded,
                count: dislikes,
                isActive: currentReaction == 'dislike',
                onPressed: onDislikePressed,
                activeColor: JadalColors.negativeRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
