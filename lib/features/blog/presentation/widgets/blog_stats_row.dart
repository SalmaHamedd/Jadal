import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';

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
      padding: EdgeInsets.symmetric(vertical: context.hp(1), horizontal: context.wp(3)),
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

          Row(
            children: [
              IconButton(
                icon: Icon(Icons.thumb_up, size: 20),
                color: currentReaction == 'like' ? JadalColors.primaryOrange : JadalColors.judgesGrey,
                onPressed: isReacting ? null : onLikePressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Text(
                '$likes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: currentReaction == 'like' ? JadalColors.primaryOrange : JadalColors.judgesGrey,
                ),
              ),
            ],
          ),

          Row(
            children: [
              IconButton(
                icon: Icon(Icons.thumb_down, size: 20),
                color: currentReaction == 'dislike' ? JadalColors.primaryOrange : JadalColors.judgesGrey,
                onPressed: isReacting ? null : onDislikePressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Text(
                '$dislikes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: currentReaction == 'dislike' ? JadalColors.primaryOrange : JadalColors.judgesGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}