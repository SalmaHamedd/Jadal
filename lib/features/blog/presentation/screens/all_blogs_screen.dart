import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_card.dart';
import 'package:jadal_app/features/blog/presentation/screens/blog_details_screen.dart';
import 'package:jadal_app/features/blog/presentation/screens/create_blog_screen.dart';

class AllBlogsScreen extends StatelessWidget {
  const AllBlogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع المقالات'),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocProvider(
        create: (_) {
          final BlogRepository repository = BlogRepositoryImpl();
          return BlogCubit(repository)..loadBlogs();
        },
        child: BlocBuilder<BlogCubit, BlogState>(
          builder: (context, state) {
            if (state is BlogLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is BlogLoaded) {
              final blogs = state.blogs;
              if (blogs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لا توجد مقالات'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToCreateBlog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('إنشاء مقال'),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: JadalColors.primaryOrange,
                onRefresh: () => context.read<BlogCubit>().loadBlogs(),
                child: ListView.builder(
                  padding: EdgeInsets.all(12).copyWith(bottom: 80),
                  itemCount: blogs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _CreateBlogBox(
                        onTap: () => _navigateToCreateBlog(context),
                      );
                    }
                    final blog = blogs[index - 1];
                    return BlogCard(
                      blog: blog,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlogDetailsScreen(slug: blog.slug),
                          ),
                        );
                        if (context.mounted) {
                          context.read<BlogCubit>().loadBlogs();
                        }
                      },
                    );
                  },
                ),
              );
            } else if (state is BlogError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('خطأ: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<BlogCubit>().loadBlogs(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _navigateToCreateBlog(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateBlogScreen()),
    );
    if (result == true && context.mounted) {
      context.read<BlogCubit>().loadBlogs();
    }
  }
}

class _CreateBlogBox extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateBlogBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: context.hp(1.5)),
      padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(1.5)),
      decoration: BoxDecoration(
        color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: context.wp(4),
              backgroundColor: JadalColors.primaryOrange,
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 22,
              ),
            ),
            SizedBox(width: context.wp(3)),
            Expanded(
              child: Text(
                'ماذا تريد أن تكتب؟ انشر مقالاً جديداً...',
                style: TextStyle(
                  color: isDark ? JadalColors.darkTextSecondary : Colors.grey[600],
                  fontSize: context.fontSize(15),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? JadalColors.darkTextSecondary : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}