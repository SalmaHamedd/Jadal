import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/home_blog_section.dart';
import 'package:jadal_app/features/home/data/home_prefetch.dart';
import 'package:jadal_app/features/home/presentation/widgets/home_debate_banner.dart';
import 'package:jadal_app/features/home/presentation/widgets/top_debaters_preview.dart';
import 'package:jadal_app/features/main/presentation/screens/main_screen.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:jadal_app/features/search/presentation/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// §2.4 — the welcome message in its own dedicated surface: a full-width
/// soft card matching the app's floating-card look, with the greeting at
/// headline size instead of the old cramped subtitle line.
class _WelcomeCard extends StatelessWidget {
  final String greeting;
  const _WelcomeCard({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color:
            (isDark ? JadalColors.darkSurfaceElevated : JadalColors.lightSurface)
                .withValues(alpha: isDark ? 0.85 : 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : JadalColors.primaryBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        greeting,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.headline(context).copyWith(
          color: isDark
              ? JadalColors.darkTextPrimary
              : JadalColors.lightTextPrimary,
        ),
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
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final titleColor = isDark
                  ? JadalColors.darkTextPrimary
                  : JadalColors.deepBlue;
              return Text(
                context.loc.navHome,
                style: AppTextStyles.displayTitle(
                  context,
                ).copyWith(color: titleColor),
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
        body: Builder(
          builder: (context) {
            // §2.6b — one shared 16px gutter for every block (the old mix of
            // extra per-section paddings made the screen read as unrelated
            // stacked parts), with an even 18px vertical rhythm.
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // §2.4 — the welcome message gets its own surface card
                    // (no text straight on the background, §2.6a) and a
                    // noticeably larger size; the waving hand is gone.
                    BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, state) {
                        final greeting = state is ProfileLoaded
                            ? context.loc.greetingWithName(state.profile.name)
                            : context.loc.greeting;
                        return _WelcomeCard(greeting: greeting);
                      },
                    ),
                    const SizedBox(height: 18),
                    const HomeDebateBanner(),
                    const SizedBox(height: 18),
                    // V2 §4 — top-3 of the points leaderboard, between the
                    // banner and the blog strip; "show more" → full public
                    // statistics.
                    const TopDebatersPreview(),
                    const SizedBox(height: 18),
                    const HomeBlogSection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
