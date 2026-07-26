import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/screens/all_blogs_screen.dart';
import 'package:jadal_app/features/blog/presentation/screens/blog_details_screen.dart';

const int kHomeLatestArticlesCount = 1;

/// Home screen's "latest article" strip — title only, no cover image (the
/// banner above is the one colorful element on this screen), sized to fill
/// whatever space is left rather than scrolling internally.
class HomeBlogSection extends StatelessWidget {
  const HomeBlogSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<BlogCubit, BlogState>(
      builder: (context, state) {
        if (state is BlogLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BlogLoaded) {
          final blogs = state.blogs;
          final displayed = blogs.take(kHomeLatestArticlesCount).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.loc.latestArticles,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: context.fontSize(18),
                        fontWeight: FontWeight.bold,
                        color: JadalColors.primaryBlue,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllBlogsScreen()),
                      ),
                      child: Text(
                        context.loc.viewAll,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: JadalColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (displayed.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(context.loc.noArticles,
                        style: TextStyle(color: JadalColors.judgesGrey, fontSize: context.fontSize(14))),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
                    itemCount: displayed.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: (isDark ? JadalColors.darkTextSecondary : JadalColors.lightTextSecondary)
                          .withValues(alpha: 0.15),
                    ),
                    itemBuilder: (context, index) {
                      final blog = displayed[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.article_outlined,
                            color: isDark ? JadalColors.darkTextSecondary : JadalColors.primaryBlue),
                        title: Text(
                          blog.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: context.fontSize(14),
                            fontWeight: FontWeight.w600,
                            color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                          ),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BlogDetailsScreen(slug: blog.slug)),
                          );
                          if (context.mounted) context.read<BlogCubit>().loadBlogs();
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        } else if (state is BlogError) {
          return Center(child: Text(context.loc.errorWithMessage(state.message)));
        }
        return const SizedBox();
      },
    );
  }
}
