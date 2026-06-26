import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_details_cubit.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_reaction_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_cover_image.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_author_info.dart';
import 'package:jadal_app/features/blog/presentation/widgets/blog_stats_row.dart';

class BlogDetailsScreen extends StatefulWidget {
  final String slug;
  const BlogDetailsScreen({super.key, required this.slug});

  @override
  State<BlogDetailsScreen> createState() => _BlogDetailsScreenState();
}

class _BlogDetailsScreenState extends State<BlogDetailsScreen> {
  late int _optimisticLikes;
  late int _optimisticDislikes;
  String? _optimisticReaction;
  bool _isReacting = false;
  int? _blogId;
  bool _isDeleting = false;
  bool _isAuthor = false;

  final PreferencesDatabase _prefs = PreferencesDatabase();

  @override
  void initState() {
    super.initState();
    _loadSavedReaction();
  }

  Future<void> _loadSavedReaction() async {
    final userId = await _prefs.getValue<int>('user_id');
    if (userId != null) {
      final reaction = await _prefs.getValue<String>('reaction_${userId}_${widget.slug}');
      if (mounted) setState(() => _optimisticReaction = reaction);
    }
  }

  Future<void> _saveReaction(String? reaction) async {
    final userId = await _prefs.getValue<int>('user_id');
    if (userId == null) return;
    final key = 'reaction_${userId}_${widget.slug}';
    if (reaction == null) {
      await _prefs.removeValue(key);
    } else {
      await _prefs.setValue(key, reaction);
    }
    if (mounted) setState(() => _optimisticReaction = reaction);
  }

  Future<void> _handleReaction(BuildContext ctx, String type) async {
    if (_isReacting || _blogId == null) return;

    final currentLikes = _optimisticLikes;
    final currentDislikes = _optimisticDislikes;
    final currentReaction = _optimisticReaction;

    int newLikes = currentLikes;
    int newDislikes = currentDislikes;
    String? newReaction;

    if (currentReaction == type) {
      newReaction = null;
      if (type == 'like') newLikes = currentLikes - 1;
      else newDislikes = currentDislikes - 1;
    } else {
      newReaction = type;
      if (type == 'like') {
        newLikes = currentLikes + 1;
        if (currentReaction == 'dislike') newDislikes = currentDislikes - 1;
      } else {
        newDislikes = currentDislikes + 1;
        if (currentReaction == 'like') newLikes = currentLikes - 1;
      }
    }

    setState(() {
      _optimisticLikes = newLikes;
      _optimisticDislikes = newDislikes;
      _optimisticReaction = newReaction;
    });

    _isReacting = true;
    final cubit = ctx.read<BlogReactionCubit>();
    await cubit.reactToBlog(_blogId!, type);
    _isReacting = false;
  }

  Future<void> _confirmDelete(int blogId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المقال'),
        content: Text('هل أنت متأكد من حذف المقال "$title"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
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

    final repository = BlogRepositoryImpl();
    final result = await repository.deleteBlog(blogId);
    result.fold(
      (failure) {
        JadalSnackBar.show(context, failure.message, type: SnackBarType.error);
        setState(() => _isDeleting = false);
      },
      (_) {
        JadalSnackBar.show(context, 'تم حذف المقال بنجاح', type: SnackBarType.success);
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final BlogRepository repository = BlogRepositoryImpl();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider<BlogDetailsCubit>(
          create: (_) => BlogDetailsCubit(repository)..loadBlogDetails(widget.slug),
        ),
        BlocProvider<BlogReactionCubit>(
          create: (_) => BlogReactionCubit(repository),
        ),
      ],
      child: Scaffold(
        backgroundColor: isDark ? JadalColors.darkBackground : JadalColors.lightBackground,
        appBar: AppBar(
          title: const Text('تفاصيل المقال'),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_isAuthor && !_isDeleting)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(_blogId!, ''),
                tooltip: 'حذف المقال',
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
                _optimisticLikes = blog.likesCount;
                _optimisticDislikes = blog.dislikesCount;
                _prefs.getValue<int>('user_id').then((userId) {
                  if (mounted) {
                    setState(() {
                      _isAuthor = userId != null && userId == blog.author.id;
                    });
                  }
                });
              }

              return BlocListener<BlogReactionCubit, BlogReactionState>(
                listener: (context, reactionState) {
                  if (reactionState is BlogReactionSuccess) {
                    setState(() {
                      _optimisticLikes = reactionState.likesCount;
                      _optimisticDislikes = reactionState.dislikesCount;
                      _optimisticReaction = reactionState.currentReaction;
                    });
                    _saveReaction(reactionState.currentReaction);
                  } else if (reactionState is BlogReactionError) {
                    JadalSnackBar.show(context, reactionState.message);
                    setState(() {
                      _optimisticLikes = blog.likesCount;
                      _optimisticDislikes = blog.dislikesCount;
                    });
                  }
                },
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (blog.coverImageUrl != null)
                        BlogCoverImage(imageUrl: blog.coverImageUrl!, isDark: isDark),
                      Padding(
                        padding: EdgeInsets.all(context.wp(5)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blog.title,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: context.fontSize(24, min: 20, max: 28),
                                fontWeight: FontWeight.bold,
                                color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            BlogAuthorInfo(
                              author: blog.author,
                              publishedAt: blog.publishedAt,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            Divider(color: isDark ? JadalColors.darkSurfaceElevated : Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              blog.content,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: context.fontSize(16),
                                height: 1.8,
                                color: isDark ? JadalColors.darkTextSecondary : JadalColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            BlogStatsRow(
                              views: blog.views,
                              likes: _optimisticLikes,
                              dislikes: _optimisticDislikes,
                              currentReaction: _optimisticReaction,
                              onLikePressed: () => _handleReaction(context, 'like'),
                              onDislikePressed: () => _handleReaction(context, 'dislike'),
                              isReacting: _isReacting,
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
                    Icon(Icons.error_outline, size: 60, color: JadalColors.judgesGrey),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ: ${detailsState.message}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.read<BlogDetailsCubit>().loadBlogDetails(widget.slug),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JadalColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
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
}