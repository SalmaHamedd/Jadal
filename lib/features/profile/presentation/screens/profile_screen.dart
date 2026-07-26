import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
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
import 'package:jadal_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_action_button.dart';
import 'package:jadal_app/features/profile/presentation/widgets/team_membership_list.dart';
import 'package:jadal_app/features/profile/presentation/widgets/user_debates_section.dart';
import 'package:jadal_app/features/statistics/data/repositories/attendance_stats_repository.dart';
import 'package:jadal_app/features/statistics/presentation/pages/attendance_stats_screen.dart';
import 'package:jadal_app/features/statistics/presentation/pages/coach_team_summary_screen.dart';
import 'package:jadal_app/features/statistics/presentation/pages/debater_stats_screen.dart';
import 'package:jadal_app/features/surveys/presentation/screens/surveys_screen.dart';
import 'package:jadal_app/features/surveys/presentation/screens/trainer_surveys_screen.dart';

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
      repo.getUserAchievements(profile.id).then((r) => r.fold((_) {}, (a) => _achievements = a)),
    ];
    if (profile.role == 'debater' || profile.role == 'trainer') {
      futures.add(repo.getUserTeams(profile.id).then((r) => r.fold((_) {}, (t) => _teams = t)));
    }
    if (profile.role == 'debater' || profile.role == 'judge') {
      futures.add(di.sl<LiveDebateRepository>()
          .searchDebates(
            DebateSearchFilter(userIds: [profile.id], status: const ['completed', 'cancelled']),
            perPage: kLatestDebatesPreviewCount,
          )
          .then((r) => r.fold((_) {}, (page) => _debates = page.items)));
    }
    await Future.wait(futures);
    if (mounted) setState(() {});
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cubit.logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
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
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is ProfileLogoutSuccess) {
            JadalSnackBar.show(context, state.message, type: SnackBarType.success);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }

          if (state is ProfileError) {
            JadalSnackBar.show(context, state.message, type: SnackBarType.error);
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
                      // ── Header card: identity + role + points ─────────────
                      _FloatingCard(
                        child: Column(
                          children: [
                            ProfileAvatar(
                              name: profile.name,
                              avatarUrl: profile.avatarUrl,
                            ),
                            SizedBox(height: context.hp(1)),
                            Text(
                              profile.name,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: context.fontSize(22),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: context.hp(1)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _HeaderChip(
                                  icon: Icons.badge_outlined,
                                  // Display-only rename — wire value stays 'trainer'.
                                  label: profile.role == 'trainer' ? 'Coach' : profile.role,
                                  color: JadalColors.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                _HeaderChip(
                                  icon: Icons.star_rounded,
                                  label: '${profile.points} pts',
                                  color: JadalColors.primaryOrange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.hp(2)),
                      // ── Private details, grouped up top (V2 §8) ───────────
                      _FloatingCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Private details',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: context.fontSize(15),
                                fontWeight: FontWeight.w800,
                                color: JadalColors.primaryBlue,
                              ),
                            ),
                            SizedBox(height: context.hp(1)),
                            _DetailRow(icon: Icons.email_outlined, label: 'Email', value: profile.email),
                            _DetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: profile.phone ?? 'Not provided',
                            ),
                            if (profile.age != null)
                              _DetailRow(icon: Icons.cake_outlined, label: 'Age', value: '${profile.age}'),
                            if (profile.location != null && profile.location!.isNotEmpty)
                              _DetailRow(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                value: profile.location!,
                              ),
                            _DetailRow(
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
                              text: 'Edit Profile',
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
                              text: 'Change Password',
                              icon: Icons.lock,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChangePasswordScreen(),
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
                          // Entry point to the debater statistics screens (moved
                          // here from the debates-list app bar).
                          if (profile.role == 'debater')
                            Expanded(
                              child: ProfileActionButton(
                                text: 'Statistics',
                                icon: Icons.insights_rounded,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DebaterStatsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (profile.role == 'debater') const SizedBox(width: 12),
                          // V2 §3 — the coach's cross-team averages.
                          if (profile.role == 'trainer')
                            Expanded(
                              child: ProfileActionButton(
                                text: 'Team analysis',
                                icon: Icons.groups_rounded,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CoachTeamSummaryScreen(
                                        trainerId: profile.id,
                                        trainerName: profile.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (profile.role == 'trainer') const SizedBox(width: 12),
                          Expanded(
                            child: ProfileActionButton(
                              text: profile.role == 'debater' ? 'Prep attendance' : 'Attendance',
                              icon: Icons.event_available_rounded,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttendanceStatsScreen(
                                      role: switch (profile.role) {
                                        'judge' => AttendanceRole.judge,
                                        'trainer' => AttendanceRole.trainer,
                                        _ => AttendanceRole.debater,
                                      },
                                      userId: profile.id,
                                      userName: profile.name,
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
                      if (_achievements.isNotEmpty) SizedBox(height: context.hp(2)),
                      if (profile.role == 'debater' || profile.role == 'trainer') ...[
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text('Teams',
                              style: TextStyle(
                                  fontFamily: 'Cairo', fontSize: context.fontSize(15), fontWeight: FontWeight.w800)),
                        ),
                        TeamMembershipSection(userId: profile.id, current: _teams),
                        SizedBox(height: context.hp(2)),
                      ],
                      if (profile.role == 'debater' || profile.role == 'judge') ...[
                        UserDebatesSection(userId: profile.id, userName: profile.name, latest: _debates),
                        SizedBox(height: context.hp(2)),
                      ],
                      // ── V2 §9 — statistics visibility opt-out ─────────────
                      _FloatingCard(
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined, color: JadalColors.primaryBlue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Share my statistics',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: context.fontSize(14),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Others can view your analysis and see you on the leaderboards',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: context.fontSize(11.5),
                                      color: JadalColors.judgesGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: profile.statsVisible,
                              activeThumbColor: JadalColors.primaryOrange,
                              onChanged: (v) => _cubit.setStatsVisibility(v),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.hp(2)),
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
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _cubit.loadProfile(),
                    child: const Text('Retry'),
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

/// The V2 §8 "floating card": every profile section sits on one of these
/// instead of painting straight onto the shared gradient. Mirrors the
/// statistics screens' StatsCard look so the app's elevated surfaces match.
class _FloatingCard extends StatelessWidget {
  final Widget child;
  const _FloatingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (dark ? JadalColors.darkSurfaceElevated : JadalColors.lightSurface)
            .withValues(alpha: dark ? 0.85 : 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.07)
              : JadalColors.primaryBlue.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.06),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small icon+label pill used in the header card (role, points).
class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeaderChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// One compact label/value line inside the private-details card.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: JadalColors.primaryBlue),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: JadalColors.judgesGrey,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}