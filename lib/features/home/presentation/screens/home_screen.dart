import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/home_blog_section.dart';
import 'package:jadal_app/features/home/presentation/widgets/home_debate_banner.dart';
import 'package:jadal_app/features/home/presentation/widgets/top_debaters_preview.dart';
import 'package:jadal_app/features/main/presentation/screens/main_screen.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/profile_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BlogCubit>(
          create: (_) {
            final BlogRepository repository = BlogRepositoryImpl();
            return BlogCubit(repository)..loadBlogs();
          },
        ),
        BlocProvider<ProfileCubit>(
          create: (_) {
            final ProfileRepository repository = ProfileRepository();
            return ProfileCubit(repository)..loadProfile();
          },
        ),
      ],
      // Transparent so the MainScreen's shared gradient shows through — the tab
      // draws content only, never its own backdrop.
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final titleColor =
                isDark ? JadalColors.darkTextPrimary : JadalColors.deepBlue;
            final subtitleColor = isDark
                ? JadalColors.darkTextSecondary
                : JadalColors.lightTextSecondary;
            final titleStyle = TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: titleColor,
            );
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
                        ),
                        Text(context.loc.navHome, style: titleStyle),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: BlocBuilder<ProfileCubit, ProfileState>(
                        builder: (context, state) {
                          final greeting = state is ProfileLoaded
                              ? context.loc.greetingWithName(state.profile.name)
                              : context.loc.greeting;
                          return Text(
                            greeting,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: HomeDebateBanner(),
                    ),
                    const SizedBox(height: 12),
                    // V2 §4 — top-3 of the points leaderboard, between the
                    // banner and the blog strip; "show more" → full public
                    // statistics.
                    const TopDebatersPreview(),
                    const SizedBox(height: 12),
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
