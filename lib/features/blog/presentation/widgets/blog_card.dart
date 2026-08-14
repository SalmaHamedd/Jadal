import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jadal_app/core/constants/appImgaeAsset.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/presentation/screens/blog_details_screen.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_chips.dart';

class BlogCard extends StatelessWidget {
  final Blog blog;
  final VoidCallback? onTap;

  const BlogCard({super.key, required this.blog, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.only(bottom: context.hp(1.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      // In dark mode `darkSurface` (#162640) sits too close to the scaffold's
      // `darkBackground` (#0D1B2E) — the cards barely separated from the page.
      // `darkSurfaceElevated` (#1E3250) is the app's standard raised tone and
      // gives the list real definition.
      color: isDark
          ? JadalColors.darkSurfaceElevated
          : JadalColors.lightSurface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlogDetailsScreen(
                  slug: blog.slug,
                  initialViews: blog.views,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(context.wp(3)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    (blog.coverImageUrl != null &&
                        blog.coverImageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: blog.coverImageUrl!,
                        height: context.hp(18),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: context.hp(18),
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Image.asset(
                          AppImageAsset.blogArticlePlaceholder,
                          height: context.hp(18),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    // Every card reserves the same image height whether or not
                    // the blog has a cover, so cards stay visually balanced
                    // instead of an image-less one reading as "oddly small".
                    : Image.asset(
                        AppImageAsset.blogArticlePlaceholder,
                        height: context.hp(18),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              SizedBox(height: context.hp(1.5)),
              Text(
                blog.title,
                style: AppTextStyles.subtitle(context).copyWith(
                  color: isDark
                      ? JadalColors.darkTextPrimary
                      : JadalColors.lightTextPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (blog.categories.isNotEmpty || blog.tags.isNotEmpty) ...[
                SizedBox(height: context.hp(0.6)),
                BlogChips(categories: blog.categories, tags: blog.tags),
              ],
              SizedBox(height: context.hp(0.8)),
              Text(
                blog.excerpt,
                style: AppTextStyles.body(context).copyWith(
                  color: isDark
                      ? JadalColors.darkTextSecondary
                      : JadalColors.lightTextSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.hp(0.8)),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: JadalColors.judgesGrey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${blog.publishedAt.year}-${blog.publishedAt.month}-${blog.publishedAt.day}',
                    style: AppTextStyles.small(
                      context,
                    ).copyWith(color: JadalColors.judgesGrey),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.visibility,
                    size: 12,
                    color: JadalColors.judgesGrey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${blog.views}',
                    style: AppTextStyles.small(
                      context,
                    ).copyWith(color: JadalColors.judgesGrey),
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.favorite_border,
                    size: 12,
                    color: JadalColors.judgesGrey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${blog.likesCount}',
                    style: AppTextStyles.small(
                      context,
                    ).copyWith(color: JadalColors.judgesGrey),
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
