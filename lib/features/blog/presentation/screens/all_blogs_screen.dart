import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/blog_search_filter.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_card.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_filter_dialog.dart';
import 'package:jadal_app/features/blog/presentation/screens/blog_details_screen.dart';
import 'package:jadal_app/features/blog/presentation/screens/create_blog_screen.dart';

class AllBlogsScreen extends StatefulWidget {
  const AllBlogsScreen({super.key});

  @override
  State<AllBlogsScreen> createState() => _AllBlogsScreenState();
}

class _AllBlogsScreenState extends State<AllBlogsScreen> {
  late final BlogCubit _cubit;
  bool _searching = false;
  final _searchController = TextEditingController();
  BlogSearchFilter _filter = const BlogSearchFilter();

  bool get _isFiltering => (_filter.q ?? '').isNotEmpty || !_filter.isEmpty;

  @override
  void initState() {
    super.initState();
    final BlogRepository repository = BlogRepositoryImpl();
    _cubit = BlogCubit(repository)..loadBlogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _refresh() {
    if (_isFiltering) {
      _cubit.searchBlogs(_filter);
    } else {
      _cubit.loadBlogs();
    }
  }

  Future<void> _openFilterDialog() async {
    final result = await showDialog<BlogSearchFilter>(
      context: context,
      builder: (_) => BlogFilterDialog(initial: _filter),
    );
    if (result != null) {
      setState(() => _filter = result);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same package as the rest of the app: transparent app bar over the shared
    // gradient backdrop (design only — the blog logic is untouched).
    return JadalGradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTextStyles.body(context),
                decoration: InputDecoration(
                    hintText: context.loc.searchArticlesHint, border: InputBorder.none),
                onChanged: (v) {
                  setState(() => _filter = _filter.copyWith(q: v));
                  _refresh();
                },
              )
            : Text(context.loc.allArticles, style: AppTextStyles.title(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              if (_searching) {
                _searchController.clear();
                _filter = _filter.copyWith(q: '');
                _refresh();
              }
              _searching = !_searching;
            }),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: !_filter.isEmpty,
              smallSize: 8,
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: _openFilterDialog,
          ),
        ],
      ),
      // A proper FAB for "create a new article" — no longer a fake list item
      // that reads as just another blog card at the top of the feed.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateBlog(context),
        backgroundColor: JadalColors.primaryOrange,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: Text(context.loc.newArticle,
            style: AppTextStyles.button(context).copyWith(color: Colors.white)),
      ),
      body: BlocProvider.value(
        value: _cubit,
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
                      Text(_isFiltering ? context.loc.noResults : context.loc.noArticles),
                      const SizedBox(height: 16),
                      if (!_isFiltering)
                        ElevatedButton.icon(
                          onPressed: () => _navigateToCreateBlog(context),
                          icon: const Icon(Icons.add),
                          label: Text(context.loc.createArticle),
                        ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: JadalColors.primaryOrange,
                onRefresh: () async => _refresh(),
                child: ListView.builder(
                  padding: EdgeInsets.all(12).copyWith(bottom: 96),
                  itemCount: blogs.length,
                  itemBuilder: (context, index) {
                    final blog = blogs[index];
                    return BlogCard(
                      blog: blog,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BlogDetailsScreen(slug: blog.slug, initialViews: blog.views),
                          ),
                        );
                        if (context.mounted) _refresh();
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
                    Text(context.loc.errorWithMessage(state.message)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: Text(context.loc.retry),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      ),
    );
  }

  void _navigateToCreateBlog(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateBlogScreen()),
    );
    if (result == true && context.mounted) _refresh();
  }
}
