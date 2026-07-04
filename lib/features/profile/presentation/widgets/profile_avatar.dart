import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const ProfileAvatar({super.key, required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: context.wp(15),
        backgroundImage: CachedNetworkImageProvider(avatarUrl!),
        backgroundColor: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
        child: null,
      );
    }

    return CircleAvatar(
      radius: context.wp(15),
      backgroundColor: isDark ? JadalColors.darkSurfaceElevated : JadalColors.lightSurface,
      child: Icon(
        Icons.person,
        size: context.wp(18),
        color: isDark ? JadalColors.darkTextSecondary : JadalColors.judgesGrey,
      ),
    );
  }
}