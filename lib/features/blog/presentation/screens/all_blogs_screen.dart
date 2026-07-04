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
import 'package:jadal_app/features/blog/presentation/widgets/create_blog_box.dart';

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
                      return CreateBlogBox(
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
