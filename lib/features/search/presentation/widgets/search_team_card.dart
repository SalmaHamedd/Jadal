import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/search/domain/entities/search_team.dart';

class SearchTeamCard extends StatelessWidget {
  final SearchTeam team;

  const SearchTeamCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.only(bottom: context.hp(1.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
        },
        child: Padding(
          padding: EdgeInsets.all(context.wp(3)),
          child: Row(
            children: [
              CircleAvatar(
                radius: context.wp(8),
                backgroundColor: JadalColors.primaryOrange,
                backgroundImage: team.logoUrl != null
                    ? NetworkImage(team.logoUrl!)
                    : null,
                child: team.logoUrl == null
                    ? Icon(Icons.group, size: context.wp(8), color: Colors.white)
                    : null,
              ),
              SizedBox(width: context.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: context.fontSize(16),
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                    SizedBox(height: context.hp(0.5)),
                    Text(
                      '${team.membersCount} عضو • المدرب: ${team.trainer.name}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: context.fontSize(13),
                        color: isDark
                            ? JadalColors.darkTextSecondary
                            : JadalColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: JadalColors.primaryOrange,
                size: context.wp(6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}