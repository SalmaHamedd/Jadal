import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
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

/// A read-only team info view — reached from a profile's team list (with
/// [membership] set, so it can show role/joined/left and a "leave team"
/// action for the caller's own current membership), from search results, or
/// from the "teams you can join" browse screen (with [canJoin] set). Shows
/// the roster if it can be fetched (best-effort — there's no `GET
/// /teams/{id}`, so this reuses `GET /teams` and matches by id; a trainer
/// only sees teams they created there, a debater only sees active,
/// non-random teams they're *not* already on — so this falls back to just
/// the name whenever the team isn't in that list for the caller's role).
class TeamInfoScreen extends StatefulWidget {
  final int teamId;
  final String teamName;
  final TeamMembership? membership;
  final bool canLeave;
  final bool canJoin;

  const TeamInfoScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    this.membership,
    this.canLeave = true,
    this.canJoin = false,
  });

  @override
  State<TeamInfoScreen> createState() => _TeamInfoScreenState();
}

class _TeamInfoScreenState extends State<TeamInfoScreen> {
  final TeamRepository _repository = TeamRepositoryImpl();
  Team? _team;
  bool _loadingTeam = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final result = await _repository.getTeams();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loadingTeam = false),
      (teams) => setState(() {
        for (final t in teams) {
          if (t.id == widget.teamId) {
            _team = t;
            break;
          }
        }
        _loadingTeam = false;
      }),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'مغادرة الفريق',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيُرسل طلب مغادرة إلى مدرب الفريق للموافقة عليه. هل تريد المتابعة؟',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'السبب (اختياري)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
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
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'إرسال الطلب',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
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
        title: const Text(
          'الانضمام إلى الفريق',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيُرسل طلب انضمام إلى مدرب الفريق للموافقة عليه. هل تريد المتابعة؟',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'السبب (اختياري)',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
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
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'إرسال الطلب',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: JadalColors.positiveGreen,
                fontWeight: FontWeight.w700,
              ),
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

  String _roleLabel(String role) => switch (role) {
    'leader' => 'قائد الفريق',
    'trainer' => 'مدرب',
    _ => 'عضو',
  };

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  List<Widget> _buildInfoRows(TeamMembership? membership) {
    final rows = <Widget>[
      if (membership?.joinedAt != null)
        _InfoRow(
          icon: Icons.login_rounded,
          label: 'تاريخ الانضمام',
          value: _formatDate(membership!.joinedAt!),
        ),
      if (membership?.leftAt != null)
        _InfoRow(
          icon: Icons.logout_rounded,
          label: 'تاريخ المغادرة',
          value: _formatDate(membership!.leftAt!),
        ),
         if (_team?.createdBy != null)
        _InfoRow(
          icon: Icons.school_rounded,
          label: 'المدرب',
          value: _team!.createdBy!.name,
        ),
      if (_team?.leader != null)
        _InfoRow(
          icon: Icons.star_rounded,
          label: 'قائد الفريق',
          value: _team!.leader!.name,
        ),
      if (_team != null)
        _InfoRow(
          icon: Icons.groups_rounded,
          label: 'عدد الأعضاء',
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
    final canLeave = widget.canLeave &&
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
                      ? 'تم إرسال طلب المغادرة. في انتظار موافقة المدرب'
                      : 'تم إرسال طلب المغادرة',
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
                      ? 'تم إرسال طلب الانضمام. في انتظار موافقة المدرب'
                      : 'تم إرسال طلب الانضمام',
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
                  title: const Text(
                    'معلومات الفريق',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                    ),
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
                            ? _roleLabel(membership.role)
                            : null,
                      ),
                      if (_buildInfoRows(membership).isNotEmpty) ...[
                        SizedBox(height: context.hp(2.5)),
                        _SectionCard(children: _buildInfoRows(membership)),
                      ],
                      SizedBox(height: context.hp(2.5)),
                      if (_loadingTeam)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_team != null && _team!.members.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'الأعضاء',
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
                        const _UnavailableNotice(),
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
                            label: const Text(
                              'مغادرة الفريق',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
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
                            label: const Text(
                              'الانضمام إلى الفريق',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    color: textColor,
                  ),
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
                  label: left ? 'غادرت الفريق' : 'عضو حالي',
                  color: left
                      ? JadalColors.judgesGrey
                      : JadalColors.positiveGreen,
                ),
              if (team != null)
                _Chip(
                  label: team!.isActive ? 'الفريق نشط' : 'الفريق غير نشط',
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
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 15.5,
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
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
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
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              color: JadalColors.judgesGrey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
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
          builder: (_) => UserProfileScreen(userId: user.id, userName: user.name),
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
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 12,
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
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Shown instead of the roster/leader when the team couldn't be fetched —
/// `GET /teams` is role-scoped (a trainer only sees teams they created; a
/// debater only sees active, non-random teams they're not already on), so
/// this shows up whenever the team in question falls outside that view for
/// the caller's role.
class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice();

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
              'تفاصيل إضافية (قائد الفريق وقائمة الأعضاء) غير متاحة لك حالياً لهذا الفريق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
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
