import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/screens/all_blogs_screen.dart';
import 'package:jadal_app/features/blog/presentation/screens/blog_details_screen.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_card.dart';

const int kHomeLatestArticlesCount = 1;

/// Home screen's "latest article" strip — renders the same [BlogCard] used
/// on the all-articles screen, just capped to the single latest post. Sized
/// to its content (no internal scrolling) so it can sit inside the home
/// screen's own scroll view.
class HomeBlogSection extends StatelessWidget {
  const HomeBlogSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlogCubit, BlogState>(
      builder: (context, state) {
        if (state is BlogLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BlogLoaded) {
          final blogs = state.blogs;
          final displayed = blogs.take(kHomeLatestArticlesCount).toList();

          // §2.6b/c — aligned to the home column's shared gutter, title in
          // theme text color (blue stays an accent).
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.loc.latestArticles,
                      style: AppTextStyles.headline(context).copyWith(
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllBlogsScreen(),
                        ),
                      ),
                      child: Text(
                        context.loc.viewAll,
                        style: AppTextStyles.button(
                          context,
                        ).copyWith(color: JadalColors.primaryOrange),
                      ),
                    ),
                  ],
              ),
              if (displayed.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      context.loc.noArticles,
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(color: JadalColors.judgesGrey),
                    ),
                  ),
                )
              else
                Column(
                  children: displayed.map((blog) {
                    return BlogCard(
                      blog: blog,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlogDetailsScreen(
                              slug: blog.slug,
                              initialViews: blog.views,
                            ),
                          ),
                        );
                        if (context.mounted)
                          context.read<BlogCubit>().loadBlogs();
                      },
                    );
                  }).toList(),
                ),
            ],
          );
        } else if (state is BlogError) {
          return Center(
            child: Text(context.loc.errorWithMessage(state.message)),
          );
        }
        return const SizedBox();
      },
    );
  }
}
