import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/blog/domain/entities/author.dart';

class BlogAuthorInfo extends StatelessWidget {
  final Author author;
  final DateTime publishedAt;
  final bool isDark;

  const BlogAuthorInfo({
    super.key,
    required this.author,
    required this.publishedAt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: context.wp(3.5),
          backgroundColor: JadalColors.primaryBlue,
          backgroundImage: author.avatarUrl != null ? NetworkImage(author.avatarUrl!) : null,
          child: author.avatarUrl == null
              ? Icon(Icons.person, size: context.wp(4), color: Colors.white)
              : null,
        ),
        SizedBox(width: context.wp(2)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.name,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: context.fontSize(14),
                  fontWeight: FontWeight.w600,
                  color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                ),
              ),
              Text(
                _formatDate(publishedAt),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: context.fontSize(12),
                  color: JadalColors.judgesGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}