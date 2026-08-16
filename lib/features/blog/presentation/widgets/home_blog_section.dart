import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/constants/appImgaeAsset.dart';
import 'package:jadal_app/core/function/media_url.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/screens/all_blogs_screen.dart';
import 'package:jadal_app/features/blog/presentation/screens/blog_details_screen.dart';
import 'package:jadal_app/core/error/failure_text.dart';

const int kHomeLatestArticlesCount = 1;

/// Home's latest-article block.
/// It used to embed the same [BlogCard] the all-articles list uses — a tall
/// stack of image, title, chips, excerpt and a meta row — which is why it
/// dominated the screen and still felt generic. Here the article is presented
/// as a single **cover-led feature**: the image carries the block, the title
/// sits on a scrim over it, and only the two meta values worth glancing at
/// survive. It reads as an invitation rather than a list item.
class HomeBlogSection extends StatelessWidget {
  const HomeBlogSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlogCubit, BlogState>(
      builder: (context, state) {
        final Widget body;
        if (state is BlogLoading) {
          body = const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state is BlogLoaded) {
          final displayed = state.blogs.take(kHomeLatestArticlesCount).toList();
          if (displayed.isEmpty) {
            body = SizedBox(
              height: 110,
              child: Center(
                child: Text(
                  context.loc.noArticles,
                  style: AppTextStyles.body(context)
                      .copyWith(color: jadalTextSecondary(context)),
                ),
              ),
            );
          } else {
            body = Column(
              children: [
                for (final blog in displayed)
                  _FeatureArticle(
                    blog: blog,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlogDetailsScreen(
                            slug: blog.slug,
                            initialViews: blog.views,
                          ),
                        ),
                      );
                      if (context.mounted) {
                        context.read<BlogCubit>().loadBlogs();
                      }
                    },
                  ),
              ],
            );
          }
        } else if (state is BlogError) {
          body = SizedBox(
            height: 110,
            child: Center(
              child: Text(
                FailureText.fromMessage(context, state.message),
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context)
                    .copyWith(color: jadalTextSecondary(context)),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }

        return JadalSurface(
          accent: JadalColors.primaryOrange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JadalSectionHeader(
                icon: Icons.auto_stories_rounded,
                title: context.loc.latestArticles,
                accent: JadalColors.primaryOrange,
                actionLabel: context.loc.viewAll,
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllBlogsScreen()),
                ),
              ),
              const SizedBox(height: 14),
              body,
            ],
          ),
        );
      },
    );
  }
}

/// Cover image + gradient scrim + title, then a slim meta strip beneath.
class _FeatureArticle extends StatelessWidget {
  final Blog blog;
  final VoidCallback onTap;
  const _FeatureArticle({required this.blog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(blog.coverImageUrl);
    final radius = BorderRadius.circular(18);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 168,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url != null)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => ColoredBox(
                        color: JadalColors.judgesGrey.withValues(alpha: 0.18),
                      ),
                      errorWidget: (_, _, _) => Image.asset(
                        AppImageAsset.blogArticlePlaceholder,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Image.asset(
                      AppImageAsset.blogArticlePlaceholder,
                      fit: BoxFit.cover,
                    ),
                  // Scrim: dark enough at the base for white text at any image.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x33000000),
                          Color(0xE6000000),
                        ],
                        stops: [0.30, 0.58, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
              child: Row(
                children: [
                  _Meta(
                    icon: Icons.calendar_today_rounded,
                    label: '${blog.publishedAt.year}-'
                        '${blog.publishedAt.month.toString().padLeft(2, '0')}-'
                        '${blog.publishedAt.day.toString().padLeft(2, '0')}',
                  ),
                  const Spacer(),
                  _Meta(
                    icon: Icons.visibility_rounded,
                    label: '${blog.views}',
                  ),
                  const SizedBox(width: 14),
                  _Meta(
                    icon: Icons.favorite_rounded,
                    label: '${blog.likesCount}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = jadalTextSecondary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.small(context)
              .copyWith(fontWeight: FontWeight.w700, color: c),
        ),
      ],
    );
  }
}
