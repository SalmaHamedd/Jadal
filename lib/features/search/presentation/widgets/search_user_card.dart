import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/function/media_url.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/avatar_palette.dart';
import 'package:jadal_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:jadal_app/features/search/domain/entities/search_user.dart';

/// One user row in the search results. The old card buried the
/// points inside a plain subtitle string; here role and points read as
/// distinct chips, and the avatar falls back to the name's initial (matching
/// the leaderboard rows and drawer header) instead of a generic person icon.
class SearchUserCard extends StatelessWidget {
  final SearchUser user;

  const SearchUserCard({super.key, required this.user});

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
            builder: (_) => UserProfileScreen(userId: user.id, userName: user.name),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(3), vertical: context.hp(1.4)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JadalColors.primaryBlue.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Builder(builder: (context) {
                  // Resolve relative avatar paths so the image shows in
                  // the list view too; — deterministic initial color.
                  final url = resolveMediaUrl(user.avatarUrl);
                  return CircleAvatar(
                    radius: context.wp(6.5),
                    backgroundColor: userAvatarColor(user.id),
                    backgroundImage: url != null ? NetworkImage(url) : null,
                    child: url == null
                        ? Text(
                            user.name.isEmpty ? '?' : user.name.characters.first.toUpperCase(),
                            style: AppTextStyles.subtitle(context).copyWith(
                              fontWeight: FontWeight.w800,
                              color: userAvatarForeground(
                                userAvatarColor(user.id),
                              ),
                            ),
                          )
                        : null,
                  );
                }),
              ),
              SizedBox(width: context.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
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
                        _Chip(
                          label: _roleText(context, user.role),
                          color: JadalColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        _Chip(
                          label: '${user.points}',
                          color: JadalColors.primaryOrange,
                          icon: Icons.star_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                // Always points "forward" — the old hardcoded chevron_left
                // only looked right in Arabic (RTL).
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: JadalColors.primaryOrange,
                size: context.wp(6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleText(BuildContext context, String role) {
    switch (role) {
      case 'debater':
        return context.loc.roleDebater;
      case 'judge':
        return context.loc.judgeRole;
      case 'trainer':
        return context.loc.roleTrainer;
      case 'admin':
        return context.loc.roleAdmin;
      default:
        return role;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Chip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTextStyles.small(context).copyWith(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
