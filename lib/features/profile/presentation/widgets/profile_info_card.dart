import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';

class ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.only(bottom: context.hp(1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: JadalColors.primaryBlue),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(value),
      ),
    );
  }
}