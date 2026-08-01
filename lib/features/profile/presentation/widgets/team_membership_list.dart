import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/team_membership.dart';
import 'package:jadal_app/features/teams/presentation/screens/team_info_screen.dart';

/// Current teams for a user, as bordered cards (matching the survey/team
/// cards elsewhere), with a "show history" toggle that expands the past
/// memberships in place (§6.4). Renders nothing if there are no current
/// teams AND the caller hasn't asked to see history. Cards navigate to
/// [TeamInfoScreen]; the "leave team" action there only shows when
/// [isOwnProfile] is true — you can't leave someone else's team.
class TeamMembershipSection extends StatefulWidget {
  final int userId;
  final List<TeamMembership> current;
  final bool isOwnProfile;
  const TeamMembershipSection({
    super.key,
    required this.userId,
    required this.current,
    this.isOwnProfile = true,
  });

  @override
  State<TeamMembershipSection> createState() => _TeamMembershipSectionState();
}

class _TeamMembershipSectionState extends State<TeamMembershipSection> {
  final ProfileRepository _repo = ProfileRepository();
  List<TeamMembership>? _history;
  bool _loadingHistory = false;

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final res = await _repo.getUserTeams(widget.userId, history: true);
    res.fold(
      (f) => setState(() {
        _history = const [];
        _loadingHistory = false;
      }),
      (items) => setState(() {
        _history = items;
        _loadingHistory = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.lightTextPrimary;

    if (widget.current.isEmpty && _history == null) {
      return _HistoryToggle(
        expanded: false,
        loading: _loadingHistory,
        onTap: _loadHistory,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in widget.current)
          _TeamMembershipCard(
            membership: t,
            textColor: textColor,
            isOwnProfile: widget.isOwnProfile,
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _HistoryToggle(
            expanded: _history != null,
            loading: _loadingHistory,
            onTap: _history == null
                ? _loadHistory
                : () => setState(() => _history = null),
          ),
        ),
        if (_history != null && !_loadingHistory)
          if (_history!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context.loc.noPastTeams,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: JadalColors.judgesGrey),
              ),
            )
          else
            for (final t in _history!)
              _TeamMembershipCard(
                membership: t,
                textColor: textColor,
                past: true,
                isOwnProfile: widget.isOwnProfile,
              ),
      ],
    );
  }
}

class _HistoryToggle extends StatelessWidget {
  final bool expanded;
  final bool loading;
  final VoidCallback? onTap;
  const _HistoryToggle({
    required this.expanded,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: loading ? null : onTap,
        style: TextButton.styleFrom(
          foregroundColor: JadalColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          visualDensity: VisualDensity.compact,
        ),
        icon: loading
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                expanded ? Icons.expand_less_rounded : Icons.history_rounded,
                size: 17,
              ),
        label: Text(
          expanded ? context.loc.hidePastTeams : context.loc.showPastTeams,
          style: AppTextStyles.caption(context),
        ),
      ),
    );
  }
}

class _TeamMembershipCard extends StatelessWidget {
  final TeamMembership membership;
  final Color textColor;
  final bool past;
  final bool isOwnProfile;
  const _TeamMembershipCard({
    required this.membership,
    required this.textColor,
    this.past = false,
    required this.isOwnProfile,
  });

  String _elapsed(BuildContext context) {
    final start = membership.joinedAt;
    if (start == null) return '';
    final end = membership.leftAt ?? DateTime.now();
    final days = end.difference(start).inDays;
    final loc = context.loc;
    if (days < 30) return loc.elapsedDaysShort(days);
    if (days < 365) return loc.elapsedMonthsShort((days / 30).round());
    return loc.elapsedYearsShort((days / 365).round());
  }

  String _roleLabel(BuildContext context) => switch (membership.role) {
    'leader' => context.loc.teamRoleLeader,
    'trainer' => context.loc.teamRoleTrainer,
    _ => context.loc.teamRoleMember,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = past ? JadalColors.judgesGrey : JadalColors.primaryOrange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? JadalColors.darkSurfaceElevated
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamInfoScreen(
              teamId: membership.teamId,
              teamName: membership.teamName,
              membership: membership,
              canLeave: isOwnProfile,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.groups_rounded, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyEmphasis(context).copyWith(
                        color: past ? JadalColors.judgesGrey : textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Pill(
                          label: _roleLabel(context),
                          color: past
                              ? JadalColors.judgesGrey
                              : JadalColors.primaryBlue,
                        ),
                        if (!past) ...[
                          const SizedBox(width: 6),
                          _Pill(
                            label: context.loc.currentPill,
                            color: JadalColors.positiveGreen,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _elapsed(context),
                style: AppTextStyles.small(
                  context,
                ).copyWith(color: JadalColors.judgesGrey),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: JadalColors.judgesGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.small(
          context,
        ).copyWith(fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
