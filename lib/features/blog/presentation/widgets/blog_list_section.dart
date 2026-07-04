import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_card.dart';
import 'package:jadal_app/features/blog/presentation/screens/blog_details_screen.dart';

class BlogListSection extends StatelessWidget {
  const BlogListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlogCubit, BlogState>(
      builder: (context, state) {
        if (state is BlogLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BlogLoaded) {
          final blogs = state.blogs;
          if (blogs.isEmpty) {
            return const Center(child: Text('لا توجد مقالات حالياً'));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(4),
                  vertical: context.hp(1),
                ),
                child: Text(
                  'جميع المقالات',
                  style: TextStyle(
                    fontSize: context.fontSize(18),
                    fontWeight: FontWeight.bold,
                    color: JadalColors.primaryBlue,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
                  itemCount: blogs.length,
                  separatorBuilder: (_, __) => SizedBox(height: context.hp(1)),
                  itemBuilder: (context, index) {
                    final blog = blogs[index];
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
