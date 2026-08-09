import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/function/media_url.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/avatar_palette.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/home_blog_section.dart';
import 'package:jadal_app/features/home/data/home_prefetch.dart';
import 'package:jadal_app/features/home/presentation/widgets/home_debate_banner.dart';
import 'package:jadal_app/features/home/presentation/widgets/top_debaters_preview.dart';
import 'package:jadal_app/features/main/presentation/screens/main_screen.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/profile.dart';
import 'package:jadal_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:jadal_app/features/search/presentation/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// The hero: avatar, greeting and name in one warm surface, with the rotating
/// debate banner mounted directly beneath it inside the same block.
///
/// The banner was previously a third free-floating element; anchoring it to
/// the greeting turns the top of the screen into a single composed unit and
/// gives the banner the prominence it deserves as the one colourful thing on
/// the screen.
class _Hero extends StatelessWidget {
  final Profile? profile;
  const _Hero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final dark = jadalIsDark(context);
    final p = profile;
    final url = resolveMediaUrl(p?.avatarUrl);
    return JadalSurface(
      accent: JadalColors.primaryOrange,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The avatar makes the greeting personal and gives the block a
              // strong anchor point on the leading edge.
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [JadalColors.primaryOrange, JadalColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: p == null
                      ? JadalColors.judgesGrey
                      : userAvatarColor(p.id),
                  backgroundImage:
                      url != null ? CachedNetworkImageProvider(url) : null,
                  child: (url == null && p != null)
                      ? Text(
                          p.name.isNotEmpty
                              ? p.name.substring(0, 1).toUpperCase()
                              : '?',
                          style: AppTextStyles.headline(context)
                              .copyWith(color: Colors.white),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.greeting,
                      style: AppTextStyles.small(context).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: JadalColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headline(context)
                          .copyWith(color: jadalTextPrimary(context)),
                    ),
                  ],
                ),
              ),
              if (p != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: JadalColors.primaryBlue
                        .withValues(alpha: dark ? 0.22 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${p.points}',
                        style: AppTextStyles.subtitle(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: JadalColors.primaryBlue,
                        ),
                      ),
                      Text(
                        context.loc.pointsLabel,
                        style: AppTextStyles.small(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: JadalColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Nested inside the hero so banner + greeting read as one unit.
          const HomeDebateBanner(),
        ],
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // §4.1 — both cubits consume the splash-time prefetch when present.
        BlocProvider<BlogCubit>(
          create: (_) {
            final BlogRepository repository = BlogRepositoryImpl();
            return BlogCubit(repository)
              ..loadBlogs(warm: HomePrefetch.takeBlogs());
          },
        ),
        BlocProvider<ProfileCubit>(
          create: (_) {
            final ProfileRepository repository = ProfileRepository();
            return ProfileCubit(repository)
              ..loadProfile(warm: HomePrefetch.takeProfile());
          },
        ),
      ],
      // Transparent so the MainScreen's shared gradient shows through — the tab
      // draws content only, never its own backdrop.
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
          ),
          title: Builder(
            builder: (context) {
              return Text(
                context.loc.navHome,
                style: AppTextStyles.displayTitle(context).copyWith(
                  color: jadalIsDark(context)
                      ? JadalColors.darkTextPrimary
                      : JadalColors.deepBlue,
                ),
              );
            },
          ),
          // §2.5 — search moved out of the bottom nav; it lives here now.
          actions: [
            IconButton(
              tooltip: context.loc.searchTitle,
              icon: const Icon(Icons.search_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JadalEntrance(
                  index: 0,
                  child: BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) => _Hero(
                      profile: state is ProfileLoaded ? state.profile : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const JadalEntrance(index: 1, child: TopDebatersPreview()),
                const SizedBox(height: 20),
                const JadalEntrance(index: 2, child: HomeBlogSection()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
