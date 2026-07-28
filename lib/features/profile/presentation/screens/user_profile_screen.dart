import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/models/debate_list_model.dart';
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/domain/debate_search_filter.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';
import 'package:jadal_app/features/profile/domain/entities/team_membership.dart';
import 'package:jadal_app/features/profile/presentation/widgets/achievements_strip.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_action_button.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_header_section.dart';
import 'package:jadal_app/features/profile/presentation/widgets/team_membership_list.dart';
import 'package:jadal_app/features/profile/presentation/widgets/user_debates_section.dart';
import 'package:jadal_app/features/statistics/data/repositories/attendance_stats_repository.dart';
import 'package:jadal_app/features/statistics/presentation/pages/attendance_stats_screen.dart';
import 'package:jadal_app/features/statistics/presentation/pages/debater_stats_screen.dart';

/// Read-only profile for ANY user (self or another) — sprinkles §6. Reached
/// from a search result tap, or from a "view profile" affordance elsewhere.
/// Layout: cover + avatar header → achievements strip → role-specific
/// section (teams for debater/coach, latest debates for debater/judge,
/// statistics buttons for all three).
class UserProfileScreen extends StatefulWidget {
  final int userId;
  final String? userName;
  const UserProfileScreen({super.key, required this.userId, this.userName});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileRepository _repo = ProfileRepository();
  PublicUserProfile? _profile;
  List<TeamMembership> _teams = const [];
  List<DebateListItem> _debates = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.getUserProfile(widget.userId);
    if (!mounted) return;
    await res.fold(
      (f) async => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (p) async {
        setState(() => _profile = p);
        final futures = <Future>[];
        if (p.role == 'debater' || p.role == 'trainer') {
          futures.add(_repo.getUserTeams(widget.userId).then((r) {
            r.fold((_) {}, (t) => _teams = t);
          }));
        }
        if (p.role == 'debater' || p.role == 'judge') {
          futures.add(di.sl<LiveDebateRepository>()
              .searchDebates(
                DebateSearchFilter(userIds: [widget.userId], status: const ['completed', 'cancelled']),
                perPage: kLatestDebatesPreviewCount,
              )
              .then((r) {
            r.fold((_) {}, (page) => _debates = page.items);
          }));
        }
        await Future.wait(futures);
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return JadalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.userName ?? _profile?.name ?? 'Profile',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : _buildBody(context, _profile!),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PublicUserProfile p) {
    return RefreshIndicator(
      onRefresh: _load,
      color: JadalColors.primaryOrange,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          ProfileHeaderSection(
            name: p.name,
            avatarUrl: p.avatarUrl,
            roleLabel: _roleLabel(p.role),
            location: p.location,
            tenure: p.tenure,
          ),
          const SizedBox(height: 20),
          AchievementsStrip(userId: p.id, userName: p.name, topAchievements: p.topAchievements),
          if (p.topAchievements.isNotEmpty) const SizedBox(height: 20),
          if (p.role == 'debater' || p.role == 'trainer') ...[
            Text('Teams',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? JadalColors.darkTextPrimary
                        : JadalColors.lightTextPrimary)),
            TeamMembershipSection(userId: p.id, current: _teams, isOwnProfile: false),
            const SizedBox(height: 20),
          ],
          if (p.role == 'debater' || p.role == 'judge') ...[
            UserDebatesSection(userId: p.id, userName: p.name, latest: _debates),
            const SizedBox(height: 20),
          ],
          _StatsButtons(profile: p),
        ],
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
        'debater' => 'Debater',
        'judge' => 'Judge',
        'trainer' => 'Coach', // display-only rename (§6.6) — wire value stays "trainer"
        'admin' => 'Admin',
        _ => role,
      };
}

class _StatsButtons extends StatelessWidget {
  final PublicUserProfile profile;
  const _StatsButtons({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (profile.role == 'debater')
          Expanded(
            child: ProfileActionButton(
              text: 'Statistics',
              icon: Icons.insights_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DebaterStatsScreen(debaterId: profile.id, debaterName: profile.name),
                ),
              ),
            ),
          ),
        if (profile.role == 'debater') const SizedBox(width: 12),
        Expanded(
          child: ProfileActionButton(
            text: profile.role == 'debater' ? 'Prep attendance' : 'Attendance',
            icon: Icons.event_available_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttendanceStatsScreen(
                  role: switch (profile.role) {
                    'judge' => AttendanceRole.judge,
                    'trainer' => AttendanceRole.trainer,
                    _ => AttendanceRole.debater,
                  },
                  userId: profile.id,
                  userName: profile.name,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
