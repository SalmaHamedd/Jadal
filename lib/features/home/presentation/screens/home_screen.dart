import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/home_blog_section.dart';
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, state) {
                      if (state is ProfileLoaded) {
                        return Text(
                          'مرحباً بك، ${state.profile.name} 👋',
                          style: titleStyle,
                        );
                      } else if (state is ProfileLoading) {
                        return Text('جاري التحميل...', style: titleStyle);
                      }
                      return Text('مرحباً بك 👋', style: titleStyle);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اكتشف أحدث المقالات والمناظرات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const HomeBlogSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}