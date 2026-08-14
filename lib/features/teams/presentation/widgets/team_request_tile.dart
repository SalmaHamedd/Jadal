import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/avatar_palette.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';

/// MF_FU §10.1/§10.2 — one pending join/leave request.
///
/// The join and leave tiles used to be duplicated line-for-line, and both were
/// filled with an 8%-alpha brand tint painted **over** the blue/orange gradient
/// background — which is why they read as mud in light theme. They now sit on
/// the app's standard surface and carry their type on a leading edge bar plus a
/// labelled pill (colour **and** text, never colour alone).
class TeamRequestTile extends StatelessWidget {
  final PublicUserProfile? user;
  final DateTime? requestedAt;
  final String? reason;
  final bool busy;
  final bool isLeaveRequest;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const TeamRequestTile({
    super.key,
    required this.user,
    required this.requestedAt,
    required this.reason,
    required this.busy,
    required this.isLeaveRequest,
    required this.onAccept,
    required this.onReject,
  });

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final accent = isLeaveRequest
        ? JadalColors.primaryOrange
        : JadalColors.primaryBlue;
    final name = user?.name ?? loc.teamRoleMember;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: JadalSurface(
        padding: EdgeInsets.zero,
        radius: 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: userAvatarColor(user?.id ?? 0),
                              backgroundImage: user?.avatarUrl != null
                                  ? NetworkImage(user!.avatarUrl!)
                                  : null,
                              child: user?.avatarUrl == null
                                  ? Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: userAvatarForeground(
                                              userAvatarColor(user?.id ?? 0),
                                            ),
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
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyEmphasis(context)
                                        .copyWith(
                                          color: jadalTextPrimary(context),
                                        ),
                                  ),
                                  if (requestedAt != null)
                                    Text(
                                      loc.teamRequestedOnDate(
                                        _formatDate(requestedAt!),
                                      ),
                                      style: AppTextStyles.small(context)
                                          .copyWith(
                                            color: jadalTextSecondary(context),
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Type carried by TEXT, not just the bar's colour.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isLeaveRequest
                                    ? loc.teamLeaveRequestPill
                                    : loc.teamJoinRequestPill,
                                style: AppTextStyles.small(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (reason != null && reason!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            reason!,
                            style: AppTextStyles.caption(context).copyWith(
                              fontStyle: FontStyle.italic,
                              color: jadalTextSecondary(context),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        RequestActions(
                          busy: busy,
                          onAccept: onAccept,
                          onReject: onReject,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// MF_FU §10.1 — the accept/reject pair.
///
/// The two buttons used to be an `OutlinedButton.icon` next to an
/// `ElevatedButton.icon`. The app's global `elevatedButtonTheme` sets
/// `minimumSize: Size.fromHeight(52)`, which only the accept button inherited,
/// so it stood ~12dp taller than reject. Both now declare the same explicit
/// `minimumSize` (which overrides the inherited one) inside an `IntrinsicHeight`,
/// so they are identical regardless of what the theme says.
class RequestActions extends StatelessWidget {
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RequestActions({
    super.key,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  static const Size _size = Size.fromHeight(44);
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 8);

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: busy ? null : onReject,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(
                loc.teamRejectButton,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.button(context),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: JadalColors.negativeRed,
                side: const BorderSide(
                  color: JadalColors.negativeRed,
                  width: 1.4,
                ),
                minimumSize: _size,
                padding: _padding,
                shape: shape,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: busy ? null : onAccept,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                loc.teamAcceptButton,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.button(context),
              ),
              style: ElevatedButton.styleFrom(
                // MF_FU §7.3 — white on positiveGreen is 3.21:1; the darker
                // fill reaches 5.34:1. Used only as a button fill, so the
                // brand green is unchanged everywhere it is a text/icon accent.
                backgroundColor: JadalColors.positiveGreenFill,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: _size,
                padding: _padding,
                shape: shape,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
