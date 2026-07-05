import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_card.dart';
import 'package:jadal_app/features/blog/presentation/screens/all_blogs_screen.dart';
import 'package:jadal_app/features/blog/presentation/screens/blog_details_screen.dart';

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
          final displayedBlogs = blogs.take(3).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'أحدث المقالات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: context.fontSize(18),
                        fontWeight: FontWeight.bold,
                        color: JadalColors.primaryBlue,
                      ),
                    ),
                    if (blogs.length > 3)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllBlogsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'عرض الكل',
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
                itemCount: displayedBlogs.length,
                separatorBuilder: (_, __) => SizedBox(height: context.hp(1)),
                itemBuilder: (context, index) {
                  final blog = displayedBlogs[index];
                  return BlogCard(
                    blog: blog,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BlogDetailsScreen(slug: blog.slug),
                        ),
                      );
                      if (context.mounted) {
                        context.read<BlogCubit>().loadBlogs();
                      }
                    },
                  );
                },
              ),
              if (blogs.length <= 3)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.hp(1)),
                  child: Center(
                    child: Text(
                      'لا توجد مقالات إضافية',
                      style: TextStyle(
                        color: JadalColors.judgesGrey,
                        fontSize: context.fontSize(14),
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else if (state is BlogError) {
          return Center(child: Text('خطأ: ${state.message}'));
        }
        return const SizedBox();
      },
    );
  }
}
