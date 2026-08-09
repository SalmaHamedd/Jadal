import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/models/debate_list_model.dart';
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/domain/debate_search_filter.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';
import 'package:jadal_app/features/profile/domain/entities/team_membership.dart';
import 'package:jadal_app/features/profile/presentation/widgets/achievements_strip.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_header_section.dart';
import 'package:jadal_app/features/profile/presentation/widgets/team_membership_list.dart';
import 'package:jadal_app/features/profile/presentation/widgets/user_debates_section.dart';
import 'package:jadal_app/features/statistics/presentation/pages/debater_stats_screen.dart';

/// Read-only profile for another user.
///
/// §6.1 — this is the SAME template as the own-profile screen: identical dome
/// cover, identical header, identical section cards, identical entrance
/// motion. The only differences are the owner-only pieces that simply don't
/// render here (private details, the edit action, logout).
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

  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _barT = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final t = (_scroll.offset / 150).clamp(0.0, 1.0);
      if ((t - _barT.value).abs() > 0.01) _barT.value = t;
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _barT.dispose();
    super.dispose();
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
          futures.add(
            _repo.getUserTeams(widget.userId).then((r) {
              r.fold((_) {}, (t) => _teams = t);
            }),
          );
        }
        if (p.role == 'debater' || p.role == 'judge') {
          futures.add(
            di
                .sl<LiveDebateRepository>()
                .searchDebates(
                  DebateSearchFilter(
                    userIds: [widget.userId],
                    status: const ['completed', 'cancelled'],
                  ),
                  perPage: kLatestDebatesPreviewCount,
                )
                .then((r) {
                  r.fold((_) {}, (page) => _debates = page.items);
                }),
          );
        }
        await Future.wait(futures);
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return JadalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // The cover runs to the very top, under the bar — same as own profile.
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ValueListenableBuilder<double>(
            valueListenable: _barT,
            builder: (context, t, _) {
              // While loading there is no cover behind the bar, so the icons
              // must use the normal foreground colour immediately.
              final over = p != null && !_loading;
              final fg = over
                  ? Color.lerp(Colors.white, jadalTextPrimary(context), t)!
                  : jadalTextPrimary(context);
              final surface = jadalIsDark(context)
                  ? JadalColors.darkBackground
                  : JadalColors.lightBackground;
              return AppBar(
                backgroundColor:
                    surface.withValues(alpha: over ? t * 0.92 : 0),
                elevation: 0,
                scrolledUnderElevation: 0,
                foregroundColor: fg,
                iconTheme: IconThemeData(color: fg),
                title: Opacity(
                  opacity: over ? t : 1,
                  child: Text(
                    widget.userName ?? p?.name ?? context.loc.navProfile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title(context).copyWith(color: fg),
                  ),
                ),
                actions: [
                  if (p != null && p.role != 'admin')
                    IconButton(
                      tooltip: context.loc.profileStatistics,
                      icon: const Icon(Icons.insights_rounded),
                      color: fg,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DebaterStatsScreen(
                            debaterId: p.id,
                            debaterName: p.name,
                            subjectRole: p.role,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                ],
              );
            },
          ),
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
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(context),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _load,
                            child: Text(context.loc.retry),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildBody(context, _profile!),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PublicUserProfile p) {
    final showTeams = p.role == 'debater' || p.role == 'trainer';
    final showDebates = p.role == 'debater' || p.role == 'judge';
    return RefreshIndicator(
      onRefresh: _load,
      color: JadalColors.primaryOrange,
      child: SingleChildScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            JadalEntrance(
              index: 0,
              child: ProfileHeaderSection(
                userId: p.id,
                name: p.name,
                avatarUrl: p.avatarUrl,
                roleLabel: _roleLabel(context, p.role),
                points: p.points,
                location: p.location,
                tenure: p.tenure,
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Column(
                children: [
                  if (p.topAchievements.isNotEmpty)
                    JadalEntrance(
                      index: 1,
                      child: AchievementsStrip(
                        userId: p.id,
                        userName: p.name,
                        topAchievements: p.topAchievements,
                      ),
                    ),
                  if (showTeams) ...[
                    if (p.topAchievements.isNotEmpty)
                      const SizedBox(height: 16),
                    JadalEntrance(
                      index: 2,
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
                              userId: p.id,
                              current: _teams,
                              isOwnProfile: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (showDebates) ...[
                    const SizedBox(height: 16),
                    JadalEntrance(
                      index: 3,
                      child: UserDebatesSection(
                        userId: p.id,
                        userName: p.name,
                        latest: _debates,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(BuildContext context, String role) => switch (role) {
    'debater' => context.loc.roleDebater,
    'judge' => context.loc.judgeRole,
    // Display-only rename (§6.6) — wire value stays "trainer".
    'trainer' => context.loc.roleTrainer,
    'admin' => context.loc.roleAdmin,
    _ => role,
  };
}
