import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
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
          color: isDark ? JadalColors.darkSurfaceElevated : Colors.grey.shade200,
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
                child: Icon(Icons.groups_rounded, color: JadalColors.primaryBlue, size: 22),
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
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: context.fontSize(15, min: 13, max: 17),
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        '${team.membersCount} أعضاء',
                        if (team.leaderName != null) 'القائد: ${team.leaderName}',
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: context.fontSize(12),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (team.isActive ? JadalColors.positiveGreen : JadalColors.judgesGrey)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  team.isActive ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: team.isActive ? JadalColors.positiveGreen : JadalColors.judgesGrey,
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
