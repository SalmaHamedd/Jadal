import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/blog/presentation/widgets/reaction_button.dart';

class BlogStatsRow extends StatelessWidget {
  final int views;
  final int likes;
  final int dislikes;
  final String? currentReaction;
  final VoidCallback onLikePressed;
  final VoidCallback onDislikePressed;
  final bool isReacting;
  final bool isDark;

  const BlogStatsRow({
    super.key,
    required this.views,
    required this.likes,
    required this.dislikes,
    this.currentReaction,
    required this.onLikePressed,
    required this.onDislikePressed,
    required this.isReacting,
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, size: 18, color: JadalColors.primaryBlue),
              const SizedBox(width: 6),
              Text(
                '$views',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: JadalColors.primaryBlue,
                ),
              ),
            ],
          ),

          ReactionButton(
            icon: Icons.thumb_up,
            count: likes,
            isActive: currentReaction == 'like',
            onPressed: onLikePressed,
            isLoading: isReacting,
          ),

          ReactionButton(
            icon: Icons.thumb_down,
            count: dislikes,
            isActive: currentReaction == 'dislike',
            onPressed: onDislikePressed,
            isLoading: isReacting,
          ),
        ],
      ),
    );
  }
}
