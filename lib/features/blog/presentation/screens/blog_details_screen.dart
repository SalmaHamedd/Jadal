import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_details_cubit.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_reaction_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_cover_image.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_author_info.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_chips.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_stats_row.dart';

class BlogDetailsScreen extends StatefulWidget {
  final String slug;
  // The server bumps the view count on every `GET /blog/{slug}`, so the
  // fresh count in the response already includes this very visit. Showing
  // that immediately reads as "off by one" next to whatever the list screen
  // showed before the tap, so we pin the display to that pre-visit number
  // instead — the list picks up the real new count next time it refreshes.
  final int? initialViews;
  const BlogDetailsScreen({super.key, required this.slug, this.initialViews});

  @override
  State<BlogDetailsScreen> createState() => _BlogDetailsScreenState();
}

class _BlogDetailsScreenState extends State<BlogDetailsScreen> {
  int? _blogId;
  String _blogTitle = '';
  bool _isDeleting = false;
  bool _isAuthor = false;

  final PreferencesDatabase _prefs = PreferencesDatabase();
  late final BlogRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = BlogRepositoryImpl();
  }

  Future<void> _confirmDelete(int blogId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.deleteArticle),
        content: Text(context.loc.deleteArticleConfirm(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.loc.delete),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _deleteBlog(blogId);
    }
  }

  Future<void> _deleteBlog(int blogId) async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    final result = await _repository.deleteBlog(blogId);
    result.fold(
      (failure) {
        JadalSnackBar.show(context, failure.message, type: SnackBarType.error);
        setState(() => _isDeleting = false);
      },
      (_) {
        JadalSnackBar.show(
          context,
          context.loc.articleDeleted,
          type: SnackBarType.success,
        );
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider<BlogDetailsCubit>(
          create: (_) =>
              BlogDetailsCubit(_repository)..loadBlogDetails(widget.slug),
        ),
        BlocProvider<BlogReactionCubit>(
          create: (_) => BlogReactionCubit(_repository),
        ),
      ],
      child: JadalGradientBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(context.loc.articleDetails,
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            if (_isAuthor && !_isDeleting)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(_blogId!, _blogTitle),
                tooltip: context.loc.deleteArticle,
              ),
          ],
        ),
        body: BlocBuilder<BlogDetailsCubit, BlogDetailsState>(
          builder: (context, detailsState) {
            if (detailsState is BlogDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (detailsState is BlogDetailsLoaded) {
              final blog = detailsState.blogDetails;
              if (_blogId == null) {
                _blogId = blog.id;
                _blogTitle = blog.title;
                context.read<BlogReactionCubit>().init(
                      blogId: blog.id,
                      slug: widget.slug,
                      likes: blog.likesCount,
                      dislikes: blog.dislikesCount,
                    );
                _prefs.getValue<int>('user_id').then((userId) {
                  if (mounted) {
                    setState(() {
                      _isAuthor = userId != null && userId == blog.author.id;
                    });
                  }
                });
              }

              return BlocConsumer<BlogReactionCubit, BlogReactionState>(
                listenWhen: (prev, curr) => curr.error != null && prev.error != curr.error,
                listener: (context, reactionState) {
                  JadalSnackBar.show(context, reactionState.error!, type: SnackBarType.error);
                  context.read<BlogReactionCubit>().dismissError();
                },
                builder: (context, reactionState) => SingleChildScrollView(
                  child: Column(
                    children: [
                      if (blog.coverImageUrl != null)
                        BlogCoverImage(
                          imageUrl: blog.coverImageUrl!,
                          isDark: isDark,
                        ),
                      Padding(
                        padding: EdgeInsets.all(context.wp(5)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blog.title,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: context.fontSize(
                                  24,
                                  min: 20,
                                  max: 28,
                                ),
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? JadalColors.darkTextPrimary
                                    : JadalColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            BlogAuthorInfo(
                              author: blog.author,
                              publishedAt: blog.publishedAt,
                              isDark: isDark,
                            ),
                            if (blog.categories.isNotEmpty || blog.tags.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              BlogChips(categories: blog.categories, tags: blog.tags),
                            ],
                            const SizedBox(height: 16),
                            Divider(
                              color: isDark
                                  ? JadalColors.darkSurfaceElevated
                                  : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              blog.content,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: context.fontSize(16),
                                height: 1.8,
                                color: isDark
                                    ? JadalColors.darkTextSecondary
                                    : JadalColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            BlogStatsRow(
                              views: widget.initialViews ?? blog.views,
                              likes: reactionState.likes,
                              dislikes: reactionState.dislikes,
                              currentReaction: reactionState.currentReaction,
                              onLikePressed: () =>
                                  context.read<BlogReactionCubit>().react('like'),
                              onDislikePressed: () =>
                                  context.read<BlogReactionCubit>().react('dislike'),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (detailsState is BlogDetailsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: JadalColors.judgesGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.loc.errorWithMessage(detailsState.message),
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context
                          .read<BlogDetailsCubit>()
                          .loadBlogDetails(widget.slug),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JadalColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
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
}
