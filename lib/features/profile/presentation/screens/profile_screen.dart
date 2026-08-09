import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
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
import 'package:jadal_app/features/profile/presentation/widgets/achievements_strip.dart';
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

  final ScrollController _scroll = ScrollController();

  /// 0 while the cover fills the top, 1 once it has scrolled past. Drives the
  /// app bar's fade from "floating over the artwork" to a solid bar, so the
  /// icons stay legible against both. A notifier (not setState) keeps the
  /// repaint to the app bar alone while scrolling.
  final ValueNotifier<double> _barT = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _cubit = ProfileCubit(ProfileRepository());
    _cubit.loadProfile();
    _scroll.addListener(() {
      final t = (_scroll.offset / 150).clamp(0.0, 1.0);
      if ((t - _barT.value).abs() > 0.01) _barT.value = t;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _barT.dispose();
    _cubit.close();
    super.dispose();
  }

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
            style: TextButton.styleFrom(foregroundColor: JadalColors.negativeRed),
            child: Text(context.loc.logout),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit(Profile profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          currentName: profile.name,
          currentPhone: profile.phone ?? '',
          currentAvatarUrl: profile.avatarUrl,
          currentLocation: profile.location,
          currentBirthDate: profile.birthDate,
        ),
      ),
    );
    // Always reload: an avatar-only change closes the screen via the "X"
    // button, which pops with no result, but the backend still has a new
    // avatar we need to reflect here.
    if (mounted) _cubit.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent so MainScreen's shared JadalGradientBackground shows
      // through, and the body runs behind the app bar so the cover can start
      // at the very top of the window.
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<ProfileCubit, ProfileState>(
          bloc: _cubit,
          builder: (context, state) {
            final profile = state is ProfileLoaded ? state.profile : null;
            return ValueListenableBuilder<double>(
              valueListenable: _barT,
              builder: (context, t, _) {
                final fg = Color.lerp(
                  Colors.white,
                  jadalTextPrimary(context),
                  t,
                )!;
                final surface = jadalIsDark(context)
                    ? JadalColors.darkBackground
                    : JadalColors.lightBackground;
                return AppBar(
                  backgroundColor: surface.withValues(alpha: t * 0.92),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  titleSpacing: 0,
                  foregroundColor: fg,
                  iconTheme: IconThemeData(color: fg),
                  leading: IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    color: fg,
                    onPressed: () =>
                        mainScaffoldKey.currentState?.openDrawer(),
                  ),
                  // The name only appears once the big one has scrolled away.
                  title: Opacity(
                    opacity: t,
                    child: Text(
                      profile?.name ?? context.loc.navProfile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title(context).copyWith(color: fg),
                    ),
                  ),
                  actions: profile == null
                      ? const []
                      : [
                          // §6.5 — the old full-width button row is gone; the
                          // owner-only actions are icons up here instead.
                          _BarAction(
                            icon: Icons.edit_rounded,
                            tooltip: context.loc.editProfileButton,
                            color: fg,
                            onTap: () => _openEdit(profile),
                          ),
                          if (profile.role != 'admin')
                            _BarAction(
                              icon: Icons.insights_rounded,
                              tooltip: context.loc.profileStatistics,
                              color: fg,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DebaterStatsScreen(),
                                ),
                              ),
                            ),
                          if (profile.role == 'trainer')
                            _BarAction(
                              icon: Icons.groups_rounded,
                              tooltip: context.loc.profileTeamAnalysis,
                              color: fg,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CoachTeamSummaryScreen(
                                    trainerId: profile.id,
                                    trainerName: profile.name,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                        ],
                );
              },
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
            JadalSnackBar.show(context, state.message, type: SnackBarType.error);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileError) {
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
          if (state is! ProfileLoaded) return const SizedBox();

          final profile = state.profile;
          _loadExtras(profile);
          final showTeams =
              profile.role == 'debater' || profile.role == 'trainer';
          final showDebates =
              profile.role == 'debater' || profile.role == 'judge';

          return RefreshIndicator(
            onRefresh: () => _cubit.loadProfile(),
            color: JadalColors.primaryOrange,
            child: SingleChildScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Full-bleed dome cover + avatar + name + wide chips.
                  JadalEntrance(
                    index: 0,
                    child: ProfileHeaderSection(
                      userId: profile.id,
                      name: profile.name,
                      avatarUrl: profile.avatarUrl,
                      roleLabel: _roleLabel(context, profile.role),
                      points: profile.points,
                      location: profile.location,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    child: Column(
                      children: [
                        JadalEntrance(
                          index: 1,
                          child: _PrivateDetails(profile: profile),
                        ),
                        if (_achievements.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          JadalEntrance(
                            index: 2,
                            child: AchievementsStrip(
                              userId: profile.id,
                              userName: profile.name,
                              topAchievements: _achievements,
                            ),
                          ),
                        ],
                        if (showTeams) ...[
                          const SizedBox(height: 16),
                          JadalEntrance(
                            index: 3,
                            child: JadalSurface(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  JadalSectionHeader(
                                    icon: Icons.groups_rounded,
                                    title: context.loc.teamsSection,
                                  ),
                                  const SizedBox(height: 6),
                                  TeamMembershipSection(
                                    userId: profile.id,
                                    current: _teams,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (showDebates) ...[
                          const SizedBox(height: 16),
                          JadalEntrance(
                            index: 4,
                            child: UserDebatesSection(
                              userId: profile.id,
                              userName: profile.name,
                              latest: _debates,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        // Full-width destructive action, inset by the page
                        // gutter it already sits in.
                        JadalEntrance(
                          index: 5,
                          child: _LogoutButton(onTap: _showLogoutConfirmation),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One app-bar icon action, tinted to match the bar's current fade state.
class _BarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _BarAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      color: color,
      onPressed: onTap,
    );
  }
}

/// §6.7 — the private-details card. Owner-only, so it simply never renders on
/// someone else's profile.
class _PrivateDetails extends StatelessWidget {
  final Profile profile;
  const _PrivateDetails({required this.profile});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return JadalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JadalSectionHeader(
            icon: Icons.lock_rounded,
            title: loc.privateDetails,
          ),
          const SizedBox(height: 8),
          ProfileDetailRow(
            icon: Icons.email_outlined,
            label: loc.email,
            value: profile.email,
          ),
          ProfileDetailRow(
            icon: Icons.phone_outlined,
            label: loc.fieldPhone,
            value: profile.phone?.isNotEmpty == true
                ? profile.phone!
                : loc.notProvided,
          ),
          if (profile.age != null)
            ProfileDetailRow(
              icon: Icons.cake_outlined,
              label: loc.fieldAge,
              value: '${profile.age}',
            ),
          if (profile.location != null && profile.location!.isNotEmpty)
            ProfileDetailRow(
              icon: Icons.location_on_outlined,
              label: loc.fieldLocation,
              value: profile.location!,
            ),
          ProfileDetailRow(
            icon: Icons.calendar_today_outlined,
            label: loc.fieldJoined,
            value: profile.createdAt.split('T').first,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const red = JadalColors.negativeRed;
    final dark = jadalIsDark(context);
    return Material(
      color: red.withValues(alpha: dark ? 0.18 : 0.09),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: red.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, size: 19, color: red),
              const SizedBox(width: 10),
              Text(
                context.loc.logout,
                style: AppTextStyles.button(context)
                    .copyWith(color: red, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
