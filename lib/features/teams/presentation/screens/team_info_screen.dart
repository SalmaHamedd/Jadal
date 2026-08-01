import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/profile/domain/entities/team_membership.dart';
import 'package:jadal_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:jadal_app/features/teams/data/repositories/team_repository_impl.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';
import 'package:jadal_app/features/teams/presentation/cubit/team_join_cubit.dart';
import 'package:jadal_app/features/teams/presentation/cubit/team_leave_cubit.dart';

/// A team info view — reached from a profile's team list (with [membership]
/// set, so it can show role/joined/left and a "leave team" action for the
/// caller's own current membership), from search results, or from the
/// "teams you can join" browse screen (with [canJoin] set). Fetches full
/// detail via `GET /teams/{id}`, which the backend authorizes for the
/// team's trainer, its leader, or any current member — so this only falls
/// back to the bare name/membership info on a genuine 403/404/network error.
/// If the caller already has the full [initialTeam] (e.g. the "browse teams
/// to join" list, which the backend deliberately excludes from the 403
/// above since you're not a member yet), pass it to skip the re-fetch.
class TeamInfoScreen extends StatefulWidget {
  final int teamId;
  final String teamName;
  final TeamMembership? membership;
  final bool canLeave;
  final bool canJoin;
  final Team? initialTeam;

  const TeamInfoScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    this.membership,
    this.canLeave = true,
    this.canJoin = false,
    this.initialTeam,
  });

  @override
  State<TeamInfoScreen> createState() => _TeamInfoScreenState();
}

class _TeamInfoScreenState extends State<TeamInfoScreen> {
  final TeamRepository _repository = TeamRepositoryImpl();
  Team? _team;
  bool _loadingTeam = true;
  Failure? _teamError;

  @override
  void initState() {
    super.initState();
    if (widget.initialTeam != null) {
      _team = widget.initialTeam;
      _loadingTeam = false;
    } else {
      _loadTeam();
    }
  }

  Future<void> _loadTeam() async {
    setState(() {
      _loadingTeam = true;
      _teamError = null;
    });
    final result = await _repository.getTeam(widget.teamId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loadingTeam = false;
        _teamError = failure;
      }),
      (team) => setState(() {
        _loadingTeam = false;
        _team = team;
      }),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.loc.teamLeaveDialogTitle,
          style: AppTextStyles.subtitle(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.teamLeaveDialogBody,
              style: AppTextStyles.body(context),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                hintText: context.loc.teamReasonOptionalHint,
                hintStyle: AppTextStyles.body(
                  context,
                ).copyWith(color: JadalColors.judgesGrey),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.loc.cancel,
              style: AppTextStyles.button(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.loc.teamSendRequestButton,
              style: AppTextStyles.button(context).copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TeamLeaveCubit>().leave(
        widget.teamId,
        reason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      );
    }
  }

  Future<void> _confirmJoin(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.loc.teamJoinDialogTitle,
          style: AppTextStyles.subtitle(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.teamJoinDialogBody,
              style: AppTextStyles.body(context),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                hintText: context.loc.teamReasonOptionalHint,
                hintStyle: AppTextStyles.body(
                  context,
                ).copyWith(color: JadalColors.judgesGrey),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.loc.cancel,
              style: AppTextStyles.button(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.loc.teamSendRequestButton,
              style: AppTextStyles.button(
                context,
              ).copyWith(color: JadalColors.positiveGreen),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TeamJoinCubit>().join(
        widget.teamId,
        reason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      );
    }
  }

  String _roleLabel(BuildContext context, String role) => switch (role) {
    'leader' => context.loc.teamRoleLeader,
    'trainer' => context.loc.teamRoleTrainer,
    _ => context.loc.teamRoleMember,
  };

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  List<Widget> _buildInfoRows(
    BuildContext context,
    TeamMembership? membership,
  ) {
    final rows = <Widget>[
      if (membership?.joinedAt != null)
        _InfoRow(
          icon: Icons.login_rounded,
          label: context.loc.teamJoinedDateLabel,
          value: _formatDate(membership!.joinedAt!),
        ),
      if (membership?.leftAt != null)
        _InfoRow(
          icon: Icons.logout_rounded,
          label: context.loc.teamLeftDateLabel,
          value: _formatDate(membership!.leftAt!),
        ),
      if (_team?.createdBy != null)
        _InfoRow(
          icon: Icons.school_rounded,
          label: context.loc.teamTrainerLabel,
          value: _team!.createdBy!.name,
        ),
      if (_team?.leader != null)
        _InfoRow(
          icon: Icons.star_rounded,
          label: context.loc.teamRoleLeader,
          value: _team!.leader!.name,
        ),
      if (_team != null)
        _InfoRow(
          icon: Icons.groups_rounded,
          label: context.loc.teamMembersCountLabel,
          value: '${_team!.membersCount}',
        ),
    ];
    if (rows.isEmpty) return rows;
    final last = rows.removeLast();
    rows.add((last as _InfoRow).copyWith(isLast: true));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final membership = widget.membership;
    final canLeave =
        widget.canLeave &&
        membership != null &&
        membership.leftAt == null &&
        membership.role != 'trainer';

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TeamLeaveCubit(_repository)),
        BlocProvider(create: (_) => TeamJoinCubit(_repository)),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TeamLeaveCubit, TeamLeaveState>(
            listener: (context, state) {
              if (state is TeamLeaveError) {
                JadalSnackBar.show(
                  context,
                  state.message,
                  type: SnackBarType.error,
                );
              } else if (state is TeamLeaveSuccess) {
                JadalSnackBar.show(
                  context,
                  state.request.isPending
                      ? context.loc.teamLeaveRequestPendingMsg
                      : context.loc.teamLeaveRequestSentMsg,
                  type: SnackBarType.success,
                );
                Navigator.pop(context, true);
              }
            },
          ),
          BlocListener<TeamJoinCubit, TeamJoinState>(
            listener: (context, state) {
              if (state is TeamJoinError) {
                JadalSnackBar.show(
                  context,
                  state.message,
                  type: SnackBarType.error,
                );
              } else if (state is TeamJoinSuccess) {
                JadalSnackBar.show(
                  context,
                  state.request.isPending
                      ? context.loc.teamJoinRequestPendingMsg
                      : context.loc.teamJoinRequestSentMsg,
                  type: SnackBarType.success,
                );
                Navigator.pop(context, true);
              }
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            final submitting =
                context.watch<TeamLeaveCubit>().state is TeamLeaveSubmitting;
            final submittingJoin =
                context.watch<TeamJoinCubit>().state is TeamJoinSubmitting;

            return JadalGradientBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(
                    context.loc.teamInfoTitle,
                    style: AppTextStyles.title(context),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                ),
                body: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    context.wp(5),
                    8,
                    context.wp(5),
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TeamHero(
                        teamName: widget.teamName,
                        membership: membership,
                        team: _team,
                        roleLabel: membership != null
                            ? _roleLabel(context, membership.role)
                            : null,
                      ),
                      if (_buildInfoRows(context, membership).isNotEmpty) ...[
                        SizedBox(height: context.hp(2.5)),
                        _SectionCard(
                          children: _buildInfoRows(context, membership),
                        ),
                      ],
                      SizedBox(height: context.hp(2.5)),
                      if (_loadingTeam)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_team != null) ...[
                        if (_team!.members.isNotEmpty) ...[
                          _SectionHeader(
                            title: context.loc.teamMembersHeader,
                            count: _team!.members.length,
                          ),
                          const SizedBox(height: 10),
                          _SectionCard(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            children: [
                              for (var i = 0; i < _team!.members.length; i++)
                                _MemberRow(
                                  member: _team!.members[i],
                                  isLeader:
                                      _team!.leader?.id ==
                                      _team!.members[i].userId,
                                  isLast: i == _team!.members.length - 1,
                                ),
                            ],
                          ),
                        ] else
                          Text(
                            context.loc.teamNoMembersYet,
                            style: AppTextStyles.body(
                              context,
                            ).copyWith(color: JadalColors.judgesGrey),
                          ),
                      ] else
                        _UnavailableNotice(error: _teamError),
                      if (canLeave) ...[
                        SizedBox(height: context.hp(4)),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: submitting
                                ? null
                                : () => _confirmLeave(context),
                            icon: submitting
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red,
                                  ),
                            label: Text(
                              context.loc.teamLeaveTeamAction,
                              style: AppTextStyles.button(
                                context,
                              ).copyWith(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (widget.canJoin && membership == null) ...[
                        SizedBox(height: context.hp(4)),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: submittingJoin
                                ? null
                                : () => _confirmJoin(context),
                            icon: submittingJoin
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              context.loc.teamJoinTeamAction,
                              style: AppTextStyles.button(
                                context,
                              ).copyWith(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: JadalColors.positiveGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The header "hero" block — big team icon, name, and status/role chips.
class _TeamHero extends StatelessWidget {
  final String teamName;
  final TeamMembership? membership;
  final Team? team;
  final String? roleLabel;

  const _TeamHero({
    required this.teamName,
    required this.membership,
    required this.team,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.lightTextPrimary;
    final left = membership?.leftAt != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            (isDark
                    ? JadalColors.darkSurfaceElevated
                    : JadalColors.lightSurface)
                .withValues(alpha: isDark ? 0.85 : 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : JadalColors.primaryBlue.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: JadalColors.primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: JadalColors.primaryOrange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  teamName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline(
                    context,
                  ).copyWith(color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (roleLabel != null)
                _Chip(label: roleLabel!, color: JadalColors.primaryBlue),
              if (membership != null)
                _Chip(
                  label: left
                      ? context.loc.teamChipLeft
                      : context.loc.teamChipCurrentMember,
                  color: left
                      ? JadalColors.judgesGrey
                      : JadalColors.positiveGreen,
                ),
              if (team != null)
                _Chip(
                  label: team!.isActive
                      ? context.loc.teamChipActive
                      : context.loc.teamChipInactive,
                  color: team!.isActive
                      ? JadalColors.positiveGreen
                      : JadalColors.judgesGrey,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.subtitle(context).copyWith(
            color: isDark
                ? JadalColors.darkTextPrimary
                : JadalColors.lightTextPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: JadalColors.primaryOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.small(context).copyWith(
              fontWeight: FontWeight.w800,
              color: JadalColors.primaryOrange,
            ),
          ),
        ),
      ],
    );
  }
}

/// A bordered, rounded surface used for the info and member sections —
/// the same look as the survey feature's panels.
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const _SectionCard({
    required this.children,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? JadalColors.darkSurfaceElevated
              : Colors.grey.shade200,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  _InfoRow copyWith({bool? isLast}) => _InfoRow(
    icon: icon,
    label: label,
    value: value,
    isLast: isLast ?? this.isLast,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? JadalColors.darkSurfaceElevated
                      : Colors.grey.shade100,
                ),
              ),
            ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: JadalColors.primaryBlue),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: JadalColors.judgesGrey),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyEmphasis(context).copyWith(
              color: isDark
                  ? JadalColors.darkTextPrimary
                  : JadalColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final TeamMember member;
  final bool isLeader;
  final bool isLast;
  const _MemberRow({
    required this.member,
    required this.isLeader,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = member.user;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              UserProfileScreen(userId: user.id, userName: user.name),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? JadalColors.darkSurfaceElevated
                        : Colors.grey.shade100,
                  ),
                ),
              ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: JadalColors.primaryBlue,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                      style: AppTextStyles.small(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: isDark
                      ? JadalColors.darkTextPrimary
                      : JadalColors.lightTextPrimary,
                ),
              ),
            ),
            if (isLeader) ...[
              Icon(
                Icons.star_rounded,
                size: 16,
                color: JadalColors.primaryOrange,
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: JadalColors.judgesGrey,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(color: color),
      ),
    );
  }
}

/// Shown instead of the roster/leader when `GET /teams/{id}` couldn't be
/// fetched — normally a 403 (caller is a past member, or otherwise
/// unrelated to the team) or a 404, occasionally a network error.
class _UnavailableNotice extends StatelessWidget {
  final Failure? error;
  const _UnavailableNotice({this.error});

  String _message(BuildContext context) {
    final err = error;
    if (err is ForbiddenFailure) return context.loc.teamForbiddenMsg;
    if (err is NotFoundFailure) return context.loc.teamNotFoundMsg;
    if (err is AuthFailure) return context.loc.teamAuthRequiredMsg;
    return context.loc.teamLoadFailedMsg;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JadalColors.judgesGrey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: JadalColors.judgesGrey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: JadalColors.judgesGrey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message(context),
              style: AppTextStyles.caption(context).copyWith(
                color: isDark
                    ? JadalColors.darkTextSecondary
                    : JadalColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
