import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const ProfileAvatar({super.key, required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: context.wp(15),
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: Colors.grey[200],
        child: null,
      );
    }


    return CircleAvatar(
      radius: context.wp(15),
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: context.wp(18),
        color: Colors.grey[700],
      ),
    );
  }
}