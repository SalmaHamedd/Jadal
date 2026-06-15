import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/presentation/screens/blog_details_screen.dart';

class BlogCard extends StatelessWidget {
  final Blog blog;
  final VoidCallback? onTap; // 👈 جديد

  const BlogCard({super.key, required this.blog, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.only(bottom: context.hp(1.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlogDetailsScreen(slug: blog.slug),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(context.wp(3)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (blog.coverImageUrl != null && blog.coverImageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    blog.coverImageUrl!,
                    height: context.hp(18),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: context.hp(18),
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ),
                SizedBox(height: context.hp(1.5)),
              ],
              Text(
                blog.title,
                style: TextStyle(
                  fontSize: context.fontSize(16),
                  fontWeight: FontWeight.bold,
                  color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.hp(0.8)),
              Text(
                blog.excerpt,
                style: TextStyle(
                  fontSize: context.fontSize(13),
                  color: isDark ? JadalColors.darkTextSecondary : JadalColors.lightTextSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.hp(0.8)),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: JadalColors.judgesGrey),
                  SizedBox(width: 4),
                  Text(
                    '${blog.publishedAt.year}-${blog.publishedAt.month}-${blog.publishedAt.day}',
                    style: TextStyle(fontSize: 11, color: JadalColors.judgesGrey),
                  ),
                  const Spacer(),
                  Icon(Icons.visibility, size: 12, color: JadalColors.judgesGrey),
                  SizedBox(width: 4),
                  Text(
                    '${blog.views}',
                    style: TextStyle(fontSize: 11, color: JadalColors.judgesGrey),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.favorite_border, size: 12, color: JadalColors.judgesGrey),
                  SizedBox(width: 4),
                  Text(
                    '${blog.likesCount}',
                    style: TextStyle(fontSize: 11, color: JadalColors.judgesGrey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}