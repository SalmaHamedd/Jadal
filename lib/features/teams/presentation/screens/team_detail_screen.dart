import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/live_debate/presentation/widgets/debate_screen_header.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/entities/team_join_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_leave_request.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member.dart';
import 'package:jadal_app/features/teams/domain/entities/team_member_priority.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';
import 'package:jadal_app/features/teams/presentation/cubit/team_detail_cubit.dart';
import 'package:jadal_app/features/teams/presentation/widgets/team_request_tile.dart';
import 'package:jadal_app/features/teams/presentation/widgets/user_search_picker.dart';
import 'package:jadal_app/core/error/failure_text.dart';

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
            JadalSnackBar.show(context, FailureText.fromMessage(context, state.error!), type: SnackBarType.error);
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
              // The in-body header used by statistics and the
              // debate detail, instead of a thin AppBar title that read as an
              // afterthought over the gradient. The status/leader chips moved
              // up here so the header does real work.
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: SafeArea(
                  bottom: false,
                  child: DebateScreenHeader(
                    title: team.name,
                    actions: [
                      if (team.isActive)
                        IconButton(
                          tooltip: context.loc.teamDeactivateTitle,
                          icon: state.busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.block_rounded,
                                  color: JadalColors.negativeRed,
                                ),
                          onPressed: state.busy
                              ? null
                              : () async {
                                  final confirmed = await _confirmDeactivate(
                                    context,
                                  );
                                  if (confirmed && context.mounted) {
                                    context
                                        .read<TeamDetailCubit>()
                                        .deactivate();
                                  }
                                },
                        ),
                    ],
                  ),
                ),
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
                        TeamRequestTile(
                          user: request.user,
                          requestedAt: request.requestedAt,
                          reason: request.reason,
                          isLeaveRequest: false,
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
                        TeamRequestTile(
                          user: request.user,
                          requestedAt: request.requestedAt,
                          reason: request.reason,
                          isLeaveRequest: true,
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
                        // The dragged item used to be wrapped in a
                        // Material painted with the ambient canvasColor, which
                        // drew an opaque rectangle the size of the item *plus*
                        // its 10dp margin. That is the "it takes the padding
                        // with it" artefact. A transparent Material removes the
                        // rectangle; the card's own decoration is the visual,
                        // and a small scale gives the lift.
                        proxyDecorator: (child, index, animation) =>
                            AnimatedBuilder(
                              animation: animation,
                              builder: (context, _) => Transform.scale(
                                scale:
                                    1 +
                                    0.03 *
                                        Curves.easeOut.transform(
                                          animation.value,
                                        ),
                                child: Material(
                                  color: Colors.transparent,
                                  elevation: 0,
                                  child: child,
                                ),
                              ),
                            ),
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
                          // The key belongs to the OUTER widget, and the gap
                          // lives here rather than as a margin on the tile —
                          // otherwise the drag proxy carries the gap with it.
                          return Padding(
                            key: ValueKey(member.userId),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MemberTile(
                              index: index,
                              member: member,
                              isLeader: team.leader?.id == member.userId,
                              // Dragging while a write is in flight used to be
                              // silently swallowed; the handle is disabled
                              // instead, so it visibly can't be grabbed.
                              draggable: !state.busy,
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
                            ),
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

class _MemberTile extends StatelessWidget {
  final int index;
  final TeamMember member;
  final bool isLeader;
  final bool draggable;
  final VoidCallback? onRemove;

  const _MemberTile({
    required this.index,
    required this.member,
    required this.isLeader,
    required this.draggable,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = member.user;

    return Container(
      // No margin: the list's itemBuilder owns the gap, so the drag proxy
      // doesn't inherit it.
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
          // 48×48 touch target (was a bare icon in 4dp of padding), and a
          // haptic on grab so the drag registers physically.
          if (draggable)
            ReorderableDragStartListener(
              index: index,
              child: GestureDetector(
                onTapDown: (_) => HapticFeedback.mediumImpact(),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: JadalColors.judgesGrey,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.drag_handle_rounded,
                color: JadalColors.judgesGrey.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }
}
