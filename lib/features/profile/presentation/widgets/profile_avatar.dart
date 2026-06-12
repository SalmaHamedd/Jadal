import 'package:flutter/material.dart';
import 'package:jadal_app/core/colors.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const ProfileAvatar({super.key, required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: context.wp(10),
      backgroundColor: AppColors.primaryblue,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: context.wp(10), color: Colors.white),
            )
          : null,
    );
  }
}