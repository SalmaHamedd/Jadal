import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';

class BlogCoverImage extends StatelessWidget {
  final String imageUrl;
  final bool isDark;

  const BlogCoverImage({super.key, required this.imageUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: context.hp(30),
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: context.hp(30),
            color: isDark ? JadalColors.darkSurface : Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => Container(
            height: context.hp(30),
            color: isDark ? JadalColors.darkSurface : Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
            height: context.hp(6),
          ),
        ),
      ],
    );
  }
}