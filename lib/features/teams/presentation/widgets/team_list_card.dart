import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';

/// One row in the trainer's team list — name, active/inactive status, leader
/// and a member count, styled to match the survey cards elsewhere in the app.
class TeamListCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const TeamListCard({super.key, required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Same treatment as the debate list card: elevated surface,
    // hairline, soft shadow, and a leading accent stripe carrying the team's
    // active/inactive state (with the pill's text saying it too).
    final dark = jadalIsDark(context);
    final accent = team.isActive
        ? JadalColors.positiveGreen
        : JadalColors.judgesGrey;
    final radius = BorderRadius.circular(18);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.32 : 0.07),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: dark
              ? JadalColors.darkSurfaceElevated
              : JadalColors.lightSurface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : JadalColors.primaryBlue.withValues(alpha: 0.07),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: JadalColors.primaryBlue.withValues(
                                  alpha: dark ? 0.20 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: JadalColors.primaryBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.subtitle(context)
                                        .copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: jadalTextPrimary(context),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      context.loc.teamMembersCountShort(
                                        team.membersCount,
                                      ),
                                      if (team.leaderName != null)
                                        context.loc.teamLeaderLabel(
                                          team.leaderName!,
                                        ),
                                    ].join(' • '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                          color: jadalTextSecondary(context),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                team.isActive
                                    ? context.loc.teamStatusActive
                                    : context.loc.teamStatusInactive,
                                style: AppTextStyles.small(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
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
        ),
      ),
    );
  }
}
