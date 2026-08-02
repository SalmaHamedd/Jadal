import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/auth/presentation/screens/login_screen.dart';
import 'package:jadal_app/features/main/presentation/screens/main_screen.dart';
import 'package:jadal_app/features/live_debate/data/models/debate_list_model.dart';
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/domain/debate_search_filter.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/achievement.dart';
import 'package:jadal_app/features/profile/domain/entities/profile.dart';
import 'package:jadal_app/features/profile/domain/entities/team_membership.dart';
import 'package:jadal_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:jadal_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:jadal_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:jadal_app/features/profile/presentation/widgets/achievements_strip.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_action_button.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_cards.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_header_section.dart';
import 'package:jadal_app/features/profile/presentation/widgets/team_membership_list.dart';
import 'package:jadal_app/features/profile/presentation/widgets/user_debates_section.dart';
import 'package:jadal_app/features/statistics/presentation/pages/coach_team_summary_screen.dart';
import 'package:jadal_app/features/statistics/presentation/pages/debater_stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileCubit _cubit;
  bool _extrasLoaded = false;
  List<Achievement> _achievements = const [];
  List<TeamMembership> _teams = const [];
  List<DebateListItem> _debates = const [];

  Future<void> _loadExtras(Profile profile) async {
    if (_extrasLoaded) return;
    _extrasLoaded = true;
    final repo = ProfileRepository();
    final futures = <Future>[
      repo
          .getUserAchievements(profile.id)
          .then((r) => r.fold((_) {}, (a) => _achievements = a)),
    ];
    if (profile.role == 'debater' || profile.role == 'trainer') {
      futures.add(
        repo
            .getUserTeams(profile.id)
            .then((r) => r.fold((_) {}, (t) => _teams = t)),
      );
    }
    if (profile.role == 'debater' || profile.role == 'judge') {
      futures.add(
        di
            .sl<LiveDebateRepository>()
            .searchDebates(
              DebateSearchFilter(
                userIds: [profile.id],
                status: const ['completed', 'cancelled'],
              ),
              perPage: kLatestDebatesPreviewCount,
            )
            .then((r) => r.fold((_) {}, (page) => _debates = page.items)),
      );
    }
    await Future.wait(futures);
    if (mounted) setState(() {});
  }

  String _roleLabel(BuildContext context, String role) => switch (role) {
    'debater' => context.loc.roleDebater,
    'judge' => context.loc.judgeRole,
    // Display-only rename — wire value stays 'trainer'.
    'trainer' => context.loc.roleTrainer,
    'admin' => context.loc.roleAdmin,
    _ => role,
  };

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.logout),
        content: Text(context.loc.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cubit.logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.loc.logout),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final repository = ProfileRepository();
    _cubit = ProfileCubit(repository);
    _cubit.loadProfile();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent so MainScreen's shared JadalGradientBackground shows
      // through — this tab used to paint an opaque scaffold color over it,
      // making Profile the odd screen out (V2 §8).
      backgroundColor: Colors.transparent,
      // Theme/language toggles moved to the shared nav drawer (§9).
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
              context.loc.navProfile,
              style: AppTextStyles.displayTitle(
                context,
              ).copyWith(color: titleColor),
            );
          },
        ),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is ProfileLogoutSuccess) {
            JadalSnackBar.show(
              context,
              state.message,
              type: SnackBarType.success,
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }

          if (state is ProfileError) {
            JadalSnackBar.show(
              context,
              state.message,
              type: SnackBarType.error,
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoaded) {
            final profile = state.profile;
            _loadExtras(profile);
            return RefreshIndicator(
              onRefresh: () => _cubit.loadProfile(),
              color: JadalColors.primaryOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(context.wp(5)),
                  child: Column(
                    children: [
                      // ── §6.1/§6.3 — the shared header template (cover asset
                      // behind the avatar, name, role/points pills).
                      ProfileHeaderSection(
                        userId: profile.id,
                        name: profile.name,
                        avatarUrl: profile.avatarUrl,
                        roleLabel: _roleLabel(context, profile.role),
                        points: profile.points,
                        location: profile.location,
                      ),
                      SizedBox(height: context.hp(2)),
                      // ── Private details (§6.7 — full email, aligned rows;
                      // owner-only, so it simply doesn't render on the public
                      // profile).
                      ProfileCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Private details',
                              style: AppTextStyles.subtitle(context).copyWith(
                                fontWeight: FontWeight.w800,
                                color: JadalColors.primaryBlue,
                              ),
                            ),
                            SizedBox(height: context.hp(1)),
                            ProfileDetailRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: profile.email,
                            ),
                            ProfileDetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: profile.phone ?? 'Not provided',
                            ),
                            if (profile.age != null)
                              ProfileDetailRow(
                                icon: Icons.cake_outlined,
                                label: 'Age',
                                value: '${profile.age}',
                              ),
                            if (profile.location != null &&
                                profile.location!.isNotEmpty)
                              ProfileDetailRow(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                value: profile.location!,
                              ),
                            ProfileDetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Joined',
                              value: profile.createdAt.split('T')[0],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.hp(2)),
                      Row(
                        children: [
                          Expanded(
                            child: ProfileActionButton(
                              text: context.loc.editProfileButton,
                              icon: Icons.edit,
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      currentName: profile.name,
                                      currentPhone: profile.phone ?? '',
                                      currentAvatarUrl: profile.avatarUrl,
                                      currentLocation: profile.location,
                                      currentBirthDate: profile.birthDate,
                                    ),
                                  ),
                                );
                                // Always reload: an avatar-only change closes
                                // the screen via the "X" button, which pops
                                // with no result, but the backend still has
                                // a new avatar we need to reflect here.
                                if (context.mounted) _cubit.loadProfile();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ProfileActionButton(
                              text: context.loc.changePasswordButton,
                              icon: Icons.lock,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ChangePasswordScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.hp(2)),
                      Row(
                        children: [
                          // §1.9 — every role gets a statistics entry; the
                          // screen is activity-only for judges/trainers and
                          // full for debaters (it resolves the role itself).
                          if (profile.role != 'admin')
                            Expanded(
                              child: ProfileActionButton(
                                text: context.loc.profileStatistics,
                                icon: Icons.insights_rounded,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DebaterStatsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (profile.role == 'trainer')
                            const SizedBox(width: 12),
                          // V2 §3 — the coach's cross-team averages.
                          if (profile.role == 'trainer')
                            Expanded(
                              child: ProfileActionButton(
                                text: context.loc.profileTeamAnalysis,
                                icon: Icons.groups_rounded,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CoachTeamSummaryScreen(
                                            trainerId: profile.id,
                                            trainerName: profile.name,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: context.hp(2)),
                      AchievementsStrip(
                        userId: profile.id,
                        userName: profile.name,
                        topAchievements: _achievements,
                      ),
                      if (_achievements.isNotEmpty)
                        SizedBox(height: context.hp(2)),
                      if (profile.role == 'debater' ||
                          profile.role == 'trainer') ...[
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            context.loc.teamsSection,
                            style: AppTextStyles.subtitle(
                              context,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TeamMembershipSection(
                          userId: profile.id,
                          current: _teams,
                        ),
                        SizedBox(height: context.hp(2)),
                      ],
                      if (profile.role == 'debater' ||
                          profile.role == 'judge') ...[
                        UserDebatesSection(
                          userId: profile.id,
                          userName: profile.name,
                          latest: _debates,
                        ),
                        SizedBox(height: context.hp(2)),
                      ],
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: ProfileActionButton(
                            text: 'Logout',
                            icon: Icons.logout,
                            textColor: Colors.red,
                            borderColor: Colors.red,
                            onPressed: () {
                              _showLogoutConfirmation();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.loc.errorWithMessage(state.message)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _cubit.loadProfile(),
                    child: Text(context.loc.retry),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

