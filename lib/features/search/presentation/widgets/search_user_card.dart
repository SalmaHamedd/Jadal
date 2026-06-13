import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/search/domain/entities/search_user.dart';

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
        onTap: () {
        },
        child: Padding(
          padding: EdgeInsets.all(context.wp(3)),
          child: Row(
            children: [
              CircleAvatar(
                radius: context.wp(8),
                backgroundColor: JadalColors.primaryBlue,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Icon(Icons.person, size: context.wp(8), color: Colors.white)
                    : null,
              ),
              SizedBox(width: context.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
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
                      '${_roleText(user.role)} • ${user.points} نقطة',
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

  String _roleText(String role) {
    switch (role) {
      case 'debater':
        return 'مناظر';
      case 'judge':
        return 'حكم';
      case 'trainer':
        return 'مدرب';
      case 'admin':
        return 'مدير';
      default:
        return role;
    }
  }
}