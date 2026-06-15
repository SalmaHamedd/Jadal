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
import 'package:cached_network_image/cached_network_image.dart';

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

  final PreferencesDatabase _prefs = PreferencesDatabase();

  @override
  void initState() {
    super.initState();
    _loadSavedReaction();
  }

  Future<void> _loadSavedReaction() async {
    final userId = await _prefs.getValue<int>('user_id');
    if (userId != null) {
      final reaction = await _prefs.getValue<String>(
        'reaction_${userId}_${widget.slug}',
      );
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
      if (type == 'like')
        newLikes = currentLikes - 1;
      else
        newDislikes = currentDislikes - 1;
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

  @override
  Widget build(BuildContext context) {
    final BlogRepository repository = BlogRepositoryImpl();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              BlogDetailsCubit(repository)..loadBlogDetails(widget.slug),
        ),
        BlocProvider(create: (_) => BlogReactionCubit(repository)),
      ],
      child: Scaffold(
        backgroundColor: isDark
            ? JadalColors.darkBackground
            : JadalColors.lightBackground,
        appBar: AppBar(
          title: const Text('تفاصيل المقال'),
          foregroundColor: Colors.white,
          elevation: 0,
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
              }
              final displayLikes = _optimisticLikes;
              final displayDislikes = _optimisticDislikes;
              final currentReaction = _optimisticReaction;

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
                      _optimisticReaction = _optimisticReaction;
                    });
                  }
                },
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (blog.coverImageUrl != null)
                        Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: blog.coverImageUrl!,
                              width: double.infinity,
                              height: context.hp(30),
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: context.hp(30),
                                color: isDark
                                    ? JadalColors.darkSurface
                                    : Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: context.hp(30),
                                color: isDark
                                    ? JadalColors.darkSurface
                                    : Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.6),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                height: context.hp(6),
                              ),
                            ),
                          ],
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
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: context.wp(3.5),
                                  backgroundColor: JadalColors.primaryBlue,
                                  backgroundImage: blog.author.avatarUrl != null
                                      ? NetworkImage(blog.author.avatarUrl!)
                                      : null,
                                  child: blog.author.avatarUrl == null
                                      ? Icon(
                                          Icons.person,
                                          size: context.wp(4),
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                SizedBox(width: context.wp(2)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        blog.author.name,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: context.fontSize(14),
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? JadalColors.darkTextPrimary
                                              : JadalColors.lightTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(blog.publishedAt),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: context.fontSize(12),
                                          color: JadalColors.judgesGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: context.hp(1),
                                horizontal: context.wp(3),
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? JadalColors.darkSurfaceElevated
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // views
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: 18,
                                        color: JadalColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${blog.views}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: JadalColors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // like
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.thumb_up, size: 20),
                                        color: currentReaction == 'like'
                                            ? JadalColors.primaryOrange
                                            : JadalColors.judgesGrey,
                                        onPressed: _isReacting
                                            ? null
                                            : () => _handleReaction(
                                                context,
                                                'like',
                                              ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$displayLikes',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: currentReaction == 'like'
                                              ? JadalColors.primaryOrange
                                              : JadalColors.judgesGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // dislike
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.thumb_down, size: 20),
                                        color: currentReaction == 'dislike'
                                            ? JadalColors.primaryOrange
                                            : JadalColors.judgesGrey,
                                        onPressed: _isReacting
                                            ? null
                                            : () => _handleReaction(
                                                context,
                                                'dislike',
                                              ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$displayDislikes',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: currentReaction == 'dislike'
                                              ? JadalColors.primaryOrange
                                              : JadalColors.judgesGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
                      'حدث خطأ: ${detailsState.message}',
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
