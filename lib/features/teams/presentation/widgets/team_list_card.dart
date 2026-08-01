import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';

/// One row in the trainer's team list — name, active/inactive status, leader
/// and a member count, styled to match the survey cards elsewhere in the app.
class TeamListCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const TeamListCard({super.key, required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark
              ? JadalColors.darkSurfaceElevated
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JadalColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
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
                      style: AppTextStyles.subtitle(context).copyWith(
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        context.loc.teamMembersCountShort(team.membersCount),
                        if (team.leaderName != null)
                          context.loc.teamLeaderLabel(team.leaderName!),
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: isDark
                            ? JadalColors.darkTextSecondary
                            : JadalColors.lightTextSecondary,
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
                  color:
                      (team.isActive
                              ? JadalColors.positiveGreen
                              : JadalColors.judgesGrey)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  team.isActive
                      ? context.loc.teamStatusActive
                      : context.loc.teamStatusInactive,
                  style: AppTextStyles.small(context).copyWith(
                    color: team.isActive
                        ? JadalColors.positiveGreen
                        : JadalColors.judgesGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
