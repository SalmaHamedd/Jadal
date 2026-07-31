import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_status_chip.dart';

class SurveyCard extends StatelessWidget {
  final Survey survey;
  final VoidCallback onTap;

  const SurveyCard({super.key, required this.survey, required this.onTap});

  String _formatCloses(BuildContext context, DateTime? date) {
    if (date == null) return context.loc.surveyNoCloseDate;
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) return context.loc.surveyStatusClosed;
    if (diff.inDays >= 1) return context.loc.surveyClosesInDays(diff.inDays);
    if (diff.inHours >= 1) return context.loc.surveyClosesInHours(diff.inHours);
    return context.loc.surveyClosesSoon;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final closed = survey.isClosed;
    final responded = survey.alreadyResponded;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: JadalColors.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.poll_outlined,
                      color: JadalColors.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      survey.title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: context.fontSize(15, min: 13, max: 17),
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                survey.description,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: context.fontSize(13),
                  color: isDark
                      ? JadalColors.darkTextSecondary
                      : JadalColors.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SurveyStatusChip(
                    label: closed ? context.loc.surveyStatusClosed : _formatCloses(context, survey.closesAt),
                    color: closed ? JadalColors.judgesGrey : JadalColors.primaryBlue,
                    icon: closed ? Icons.lock_clock_outlined : Icons.schedule,
                  ),
                  if (responded)
                    SurveyStatusChip(
                      label: context.loc.surveyAnsweredChip,
                      color: JadalColors.positiveGreen,
                      icon: Icons.check_circle_outline,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
