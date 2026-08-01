import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/entities/team_join_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_leave_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member_priority.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';
import 'package:jadal_app/features/teams/presentation/cubit/team_detail_cubit.dart';
import 'package:jadal_app/features/teams/presentation/widgets/user_search_picker.dart';

/// A trainer's single-team management screen: roster (drag to reorder
/// priority, swipe/tap to remove), add members via search, and deactivate.
/// [team] is whatever the caller already has (from the list) and gets
/// replaced locally after each mutation, since every write endpoint
/// already echoes back the updated team.
class TeamDetailScreen extends StatelessWidget {
  final Team team;
  final TeamRepository repository;

  const TeamDetailScreen({
    super.key,
    required this.team,
    required this.repository,
  });

  Future<bool> _confirmDeactivate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.loc.teamDeactivateTitle,
          style: AppTextStyles.subtitle(context),
        ),
        content: Text(
          context.loc.teamDeactivateConfirmBody,
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.loc.teamCancelButton,
              style: AppTextStyles.button(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.loc.teamDeactivateConfirmButton,
              style: AppTextStyles.button(context).copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<bool> _confirmRemoveMember(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.loc.teamRemoveMemberTitle,
          style: AppTextStyles.subtitle(context),
        ),
        content: Text(
          context.loc.teamRemoveMemberBody(name),
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.loc.teamCancelButton,
              style: AppTextStyles.button(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.loc.teamRemoveButton,
              style: AppTextStyles.button(context).copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<bool> _confirmRespond(
    BuildContext context,
    TeamLeaveRequest request,
    bool accept,
  ) async {
    final name = request.user?.name ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          accept
              ? context.loc.teamAcceptLeaveRequestTitle
              : context.loc.teamRejectLeaveRequestTitle,
          style: AppTextStyles.subtitle(context),
        ),
        content: Text(
          accept
              ? context.loc.teamLeaveRequestAcceptBody(name)
              : context.loc.teamLeaveRequestRejectBody(name),
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.loc.teamCancelButton,
              style: AppTextStyles.button(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              accept
                  ? context.loc.teamAcceptButton
                  : context.loc.teamRejectButton,
              style: AppTextStyles.button(context).copyWith(
                color: accept ? JadalColors.positiveGreen : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<bool> _confirmRespondJoin(
    BuildContext context,
    TeamJoinRequest request,
    bool accept,
  ) async {
    final name = request.user?.name ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          accept
              ? context.loc.teamAcceptJoinRequestTitle
              : context.loc.teamRejectJoinRequestTitle,
          style: AppTextStyles.subtitle(context),
        ),
        content: Text(
          accept
              ? context.loc.teamJoinRequestAcceptBody(name)
              : context.loc.teamJoinRequestRejectBody(name),
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.loc.teamCancelButton,
              style: AppTextStyles.button(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              accept
                  ? context.loc.teamAcceptButton
                  : context.loc.teamRejectButton,
              style: AppTextStyles.button(context).copyWith(
                color: accept ? JadalColors.positiveGreen : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _openAddMembersSheet(BuildContext context) async {
    final cubit = context.read<TeamDetailCubit>();
    final excluded = cubit.state.team.members.map((m) => m.userId).toSet();
    final picked = <int>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? JadalColors.darkSurface
                  : JadalColors.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: StatefulBuilder(
              builder: (sheetContext, setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sheetContext.loc.teamAddMembers,
                      style: AppTextStyles.title(sheetContext).copyWith(
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    UserSearchPicker(
                      excludeIds: {...excluded, ...picked},
                      onSelected: (user) =>
                          setSheetState(() => picked.add(user.id)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: picked.isEmpty
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                cubit.addMembers(picked.toList());
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JadalColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          sheetContext.loc.teamAddCount(picked.length),
                          style: AppTextStyles.button(
                            sheetContext,
                          ).copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TeamDetailCubit(repository, team)
        ..loadLeaveRequests()
        ..loadJoinRequests(),
      child: BlocConsumer<TeamDetailCubit, TeamDetailState>(
        listenWhen: (prev, curr) =>
            prev.error != curr.error || prev.deactivated != curr.deactivated,
        listener: (context, state) {
          if (state.error != null) {
            JadalSnackBar.show(context, state.error!, type: SnackBarType.error);
          }
          if (state.deactivated) {
            JadalSnackBar.show(
              context,
              context.loc.teamDeactivatedMsg,
              type: SnackBarType.success,
            );
            Navigator.pop(context, true);
          }
        },
        builder: (context, state) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final team = state.team;

          return JadalGradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(team.name, style: AppTextStyles.title(context)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                actions: [
                  if (team.isActive)
                    IconButton(
                      tooltip: context.loc.teamDeactivateTitle,
                      icon: state.busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.block_rounded, color: Colors.red),
                      onPressed: state.busy
                          ? null
                          : () async {
                              final confirmed = await _confirmDeactivate(
                                context,
                              );
                              if (confirmed && context.mounted) {
                                context.read<TeamDetailCubit>().deactivate();
                              }
                            },
                    ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: JadalColors.primaryOrange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                  context.loc.teamAddMembers,
                  style: AppTextStyles.button(
                    context,
                  ).copyWith(color: Colors.white),
                ),
                onPressed: () => _openAddMembersSheet(context),
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  context.wp(5),
                  context.wp(5),
                  context.wp(5),
                  100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(
                          label: team.isActive
                              ? context.loc.teamStatusActive
                              : context.loc.teamStatusInactive,
                          color: team.isActive
                              ? JadalColors.positiveGreen
                              : JadalColors.judgesGrey,
                        ),
                        if (team.leader != null)
                          _StatusChip(
                            label: context.loc.teamLeaderLabel(
                              team.leader!.name,
                            ),
                            color: JadalColors.primaryBlue,
                          ),
                      ],
                    ),
                    if (state.joinRequests.isNotEmpty) ...[
                      SizedBox(height: context.hp(2.5)),
                      Text(
                        context.loc.teamJoinRequestsHeader(
                          state.joinRequests.length,
                        ),
                        style: AppTextStyles.subtitle(context).copyWith(
                          color: isDark
                              ? JadalColors.darkTextPrimary
                              : JadalColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final request in state.joinRequests)
                        _JoinRequestTile(
                          request: request,
                          busy: state.busy,
                          onAccept: () async {
                            final confirmed = await _confirmRespondJoin(
                              context,
                              request,
                              true,
                            );
                            if (confirmed && context.mounted) {
                              context
                                  .read<TeamDetailCubit>()
                                  .respondToJoinRequest(
                                    request.id,
                                    accept: true,
                                  );
                            }
                          },
                          onReject: () async {
                            final confirmed = await _confirmRespondJoin(
                              context,
                              request,
                              false,
                            );
                            if (confirmed && context.mounted) {
                              context
                                  .read<TeamDetailCubit>()
                                  .respondToJoinRequest(
                                    request.id,
                                    accept: false,
                                  );
                            }
                          },
                        ),
                    ],
                    if (state.leaveRequests.isNotEmpty) ...[
                      SizedBox(height: context.hp(2.5)),
                      Text(
                        context.loc.teamLeaveRequestsHeader(
                          state.leaveRequests.length,
                        ),
                        style: AppTextStyles.subtitle(context).copyWith(
                          color: isDark
                              ? JadalColors.darkTextPrimary
                              : JadalColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final request in state.leaveRequests)
                        _LeaveRequestTile(
                          request: request,
                          busy: state.busy,
                          onAccept: () async {
                            final confirmed = await _confirmRespond(
                              context,
                              request,
                              true,
                            );
                            if (confirmed && context.mounted) {
                              context
                                  .read<TeamDetailCubit>()
                                  .respondToLeaveRequest(
                                    request.id,
                                    accept: true,
                                  );
                            }
                          },
                          onReject: () async {
                            final confirmed = await _confirmRespond(
                              context,
                              request,
                              false,
                            );
                            if (confirmed && context.mounted) {
                              context
                                  .read<TeamDetailCubit>()
                                  .respondToLeaveRequest(
                                    request.id,
                                    accept: false,
                                  );
                            }
                          },
                        ),
                    ],
                    SizedBox(height: context.hp(2.5)),
                    Text(
                      context.loc.teamMembersHeaderCount(team.members.length),
                      style: AppTextStyles.subtitle(context).copyWith(
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.loc.teamDragToReorderHint,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: JadalColors.judgesGrey),
                    ),
                    const SizedBox(height: 10),
                    if (team.members.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            context.loc.teamNoMembersYet,
                            style: AppTextStyles.body(
                              context,
                            ).copyWith(color: JadalColors.judgesGrey),
                          ),
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: team.members.length,
                        onReorder: state.busy
                            ? (_, _) {}
                            : (oldIndex, newIndex) {
                                final members = [...team.members];
                                if (newIndex > oldIndex) newIndex -= 1;
                                final moved = members.removeAt(oldIndex);
                                members.insert(newIndex, moved);
                                final priorities = [
                                  for (var i = 0; i < members.length; i++)
                                    TeamMemberPriority(
                                      userId: members[i].userId,
                                      priority: i + 1,
                                    ),
                                ];
                                context
                                    .read<TeamDetailCubit>()
                                    .updatePriorities(priorities);
                              },
                        itemBuilder: (context, index) {
                          final member = team.members[index];
                          return _MemberTile(
                            key: ValueKey(member.userId),
                            index: index,
                            member: member,
                            isLeader: team.leader?.id == member.userId,
                            onRemove: state.busy
                                ? null
                                : () async {
                                    final confirmed =
                                        await _confirmRemoveMember(
                                          context,
                                          member.user.name,
                                        );
                                    if (confirmed && context.mounted) {
                                      context
                                          .read<TeamDetailCubit>()
                                          .removeMember(member.userId);
                                    }
                                  },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

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

class _JoinRequestTile extends StatelessWidget {
  final TeamJoinRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _JoinRequestTile({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = request.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JadalColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: JadalColors.primaryBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: JadalColors.primaryBlue,
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        (user?.name.isNotEmpty ?? false)
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.small(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? context.loc.teamRoleMember,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyEmphasis(context).copyWith(
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                    if (request.requestedAt != null)
                      Text(
                        context.loc.teamRequestedOnDate(
                          _formatDate(request.requestedAt!),
                        ),
                        style: AppTextStyles.small(
                          context,
                        ).copyWith(color: JadalColors.judgesGrey),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.reason!,
              style: AppTextStyles.caption(context).copyWith(
                fontStyle: FontStyle.italic,
                color: isDark
                    ? JadalColors.darkTextSecondary
                    : JadalColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: Text(
                    context.loc.teamRejectButton,
                    style: AppTextStyles.button(
                      context,
                    ).copyWith(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onAccept,
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    context.loc.teamAcceptButton,
                    style: AppTextStyles.button(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JadalColors.positiveGreen,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestTile extends StatelessWidget {
  final TeamLeaveRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _LeaveRequestTile({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = request.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JadalColors.primaryOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: JadalColors.primaryOrange.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: JadalColors.primaryOrange,
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Text(
                        (user?.name.isNotEmpty ?? false)
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.small(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? context.loc.teamRoleMember,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyEmphasis(context).copyWith(
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                    if (request.requestedAt != null)
                      Text(
                        context.loc.teamRequestedOnDate(
                          _formatDate(request.requestedAt!),
                        ),
                        style: AppTextStyles.small(
                          context,
                        ).copyWith(color: JadalColors.judgesGrey),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.reason!,
              style: AppTextStyles.caption(context).copyWith(
                fontStyle: FontStyle.italic,
                color: isDark
                    ? JadalColors.darkTextSecondary
                    : JadalColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: Text(
                    context.loc.teamRejectButton,
                    style: AppTextStyles.button(
                      context,
                    ).copyWith(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onAccept,
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    context.loc.teamAcceptButton,
                    style: AppTextStyles.button(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JadalColors.positiveGreen,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final int index;
  final TeamMember member;
  final bool isLeader;
  final VoidCallback? onRemove;

  const _MemberTile({
    super.key,
    required this.index,
    required this.member,
    required this.isLeader,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = member.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? JadalColors.darkSurfaceElevated
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: JadalColors.primaryBlue,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyEmphasis(context).copyWith(
                          color: isDark
                              ? JadalColors.darkTextPrimary
                              : JadalColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: JadalColors.primaryOrange,
                      ),
                    ],
                  ],
                ),
                Text(
                  '#${member.priority} • ${user.role}',
                  style: AppTextStyles.small(
                    context,
                  ).copyWith(color: JadalColors.judgesGrey),
                ),
              ],
            ),
          ),
          if (!isLeader && onRemove != null)
            IconButton(
              tooltip: context.loc.teamRemoveButton,
              icon: const Icon(
                Icons.person_remove_outlined,
                color: Colors.red,
                size: 20,
              ),
              onPressed: onRemove,
            ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.drag_handle_rounded,
                color: JadalColors.judgesGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
