import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/app_cubit/app_cubit.dart';
import 'package:jadal_app/core/app_cubit/app_states.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:jadal_app/features/statistics/presentation/pages/debater_stats_screen.dart';
import 'package:jadal_app/features/surveys/presentation/screens/surveys_screen.dart';
import 'package:jadal_app/features/surveys/presentation/screens/trainer_surveys_screen.dart';

/// The app's shared navigation drawer: Statistics, Surveys, My Team Surveys
/// (trainer only), and a Settings section (language + light/dark mode).
///
/// Owns its own [ProfileCubit] (same pattern every tab already uses) just to
/// know the current role, so "My Team Surveys" only shows for trainers.
class JadalDrawer extends StatefulWidget {
  const JadalDrawer({super.key});

  @override
  State<JadalDrawer> createState() => _JadalDrawerState();
}

class _JadalDrawerState extends State<JadalDrawer> {
  late final ProfileCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ProfileCubit(ProfileRepository())..loadProfile();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? JadalColors.darkSurface : Colors.white,
      child: SafeArea(
        child: BlocProvider.value(
          value: _cubit,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: JadalColors.primaryOrange.withValues(alpha: 0.1)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.forum_rounded, color: JadalColors.primaryOrange, size: 32),
                    const SizedBox(width: 10),
                    Text(
                      'جدل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.insights_rounded, color: JadalColors.primaryOrange),
                title: const Text('الإحصائيات', style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DebaterStatsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.poll_outlined, color: JadalColors.primaryOrange),
                title: const Text('الاستطلاعات', style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SurveysScreen()),
                  );
                },
              ),
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  if (state is! ProfileLoaded || state.profile.role != 'trainer') {
                    return const SizedBox();
                  }
                  return ListTile(
                    leading: Icon(Icons.groups_2_outlined, color: JadalColors.primaryOrange),
                    title: const Text('استطلاعات فريقي', style: TextStyle(fontFamily: 'Cairo')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TrainerSurveysScreen()),
                      );
                    },
                  );
                },
              ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'الإعدادات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: JadalColors.judgesGrey,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              BlocBuilder<AppCubit, AppState>(
                buildWhen: (a, b) => a.locale != b.locale,
                builder: (context, state) {
                  final isArabic = state.locale.languageCode == 'ar';
                  return ListTile(
                    leading: Icon(Icons.language_rounded, color: JadalColors.primaryOrange),
                    title: const Text('اللغة', style: TextStyle(fontFamily: 'Cairo')),
                    trailing: Text(
                      isArabic ? 'العربية' : 'English',
                      style: TextStyle(fontFamily: 'Cairo', color: JadalColors.judgesGrey),
                    ),
                    onTap: () => context.read<AppCubit>().toggleLocale(),
                  );
                },
              ),
              BlocBuilder<AppCubit, AppState>(
                buildWhen: (a, b) => a.themeMode != b.themeMode,
                builder: (context, state) {
                  final platformBrightness = MediaQuery.platformBrightnessOf(context);
                  final isDarkMode = state.themeMode == ThemeMode.dark ||
                      (state.themeMode == ThemeMode.system && platformBrightness == Brightness.dark);
                  return ListTile(
                    leading: Icon(
                      isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: JadalColors.primaryOrange,
                    ),
                    title: const Text('الوضع الليلي', style: TextStyle(fontFamily: 'Cairo')),
                    trailing: Switch(
                      value: isDarkMode,
                      activeThumbColor: JadalColors.primaryOrange,
                      onChanged: (_) => context.read<AppCubit>().toggleTheme(platformBrightness),
                    ),
                    onTap: () => context.read<AppCubit>().toggleTheme(platformBrightness),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
