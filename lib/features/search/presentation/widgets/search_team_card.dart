import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/search/domain/entities/search_team.dart';
import 'package:jadal_app/features/teams/presentation/screens/team_info_screen.dart';

/// One team row in the search results, restyled to match
/// [SearchUserCard]: initial-letter fallback avatar, member count as a chip,
/// and the coach's name on its own line. Tap opens [TeamInfoScreen] — no
/// membership context here, so it's never leavable; [canJoin] (only true for
/// a debater viewer) lets it offer a join request instead.
class SearchTeamCard extends StatelessWidget {
  final SearchTeam team;
  final bool canJoin;

  const SearchTeamCard({super.key, required this.team, this.canJoin = false});

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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamInfoScreen(
              teamId: team.id,
              teamName: team.name,
              canLeave: false,
              canJoin: canJoin,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.wp(3),
            vertical: context.hp(1.4),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JadalColors.primaryOrange.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: context.wp(6.5),
                  backgroundColor: JadalColors.primaryOrange,
                  backgroundImage: team.logoUrl != null
                      ? NetworkImage(team.logoUrl!)
                      : null,
                  child: team.logoUrl == null
                      ? Text(
                          team.name.isEmpty
                              ? '?'
                              : team.name.characters.first.toUpperCase(),
                          style: AppTextStyles.subtitle(context)
                              .copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                        )
                      : null,
                ),
              ),
              SizedBox(width: context.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                    SizedBox(height: context.hp(0.6)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: JadalColors.primaryBlue.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_rounded,
                                size: 12,
                                color: JadalColors.primaryBlue,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                context.loc.membersCountLabel(
                                  team.membersCount,
                                ),
                                style: AppTextStyles.small(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: JadalColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.loc.coachNameLabel(team.trainer.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              color: isDark
                                  ? JadalColors.darkTextSecondary
                                  : JadalColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
