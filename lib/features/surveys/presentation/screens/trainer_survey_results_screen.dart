import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/surveys/data/repositories/trainer_survey_repository_impl.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_results.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/trainer_survey_results_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_panel.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_state_views.dart';

/// Shows the results for a trainer-created survey: a per-question summary
/// (using the server-computed `aggregate` on each question) followed by a
/// card per respondent showing exactly who answered what.
class TrainerSurveyResultsScreen extends StatelessWidget {
  final int surveyId;
  final TrainerSurveyRepository? repository;

  const TrainerSurveyResultsScreen({super.key, required this.surveyId, this.repository});

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? TrainerSurveyRepositoryImpl();

    return BlocProvider(
      create: (_) => TrainerSurveyResultsCubit(repo)..loadResults(surveyId),
      child: Builder(
        builder: (context) {
          return JadalGradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  context.loc.surveyResultsTitle,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              body: BlocBuilder<TrainerSurveyResultsCubit, TrainerSurveyResultsState>(
                builder: (context, state) {
                  if (state is TrainerSurveyResultsLoading) {
                    return const SurveyLoadingView();
                  } else if (state is TrainerSurveyResultsLoaded) {
                    return _ResultsBody(results: state.results);
                  } else if (state is TrainerSurveyResultsError) {
                    return SurveyErrorView(
                      message: state.message,
                      onRetry: () =>
                          context.read<TrainerSurveyResultsCubit>().loadResults(surveyId),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  final SurveyResults results;
  const _ResultsBody({required this.results});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (results.questions.isEmpty && results.responses.isEmpty) {
      return SurveyEmptyMessage(message: context.loc.surveyNoResponsesYet);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.wp(5)).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (results.title != null) ...[
            Text(
              results.title!,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: context.fontSize(20, min: 17, max: 24),
                color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: JadalColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline, color: JadalColors.primaryOrange),
                const SizedBox(width: 10),
                Text(
                  context.loc.surveyTotalResponsesLabel(
                    results.totalResponses ?? results.responses.length,
                  ),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    color: JadalColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.loc.surveyAnswersSummary,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: context.fontSize(16),
              color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...results.questions.map((q) => _QuestionSummaryCard(question: q, isDark: isDark)),
          if (results.responses.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              context.loc.surveyResponsesCountLabel(results.responses.length),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: context.fontSize(16),
                color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...results.responses.map(
              (r) => _RespondentCard(response: r, questions: results.questions, isDark: isDark),
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders one question's server-computed aggregate.
class _QuestionSummaryCard extends StatelessWidget {
  final SurveyResultsQuestion question;
  final bool isDark;
  const _QuestionSummaryCard({required this.question, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SurveyPanel(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if ((question.totalAnswered ?? 0) == 0)
            Text(
              context.loc.surveyNoAnswersYet,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: JadalColors.judgesGrey),
            )
          else if (question.isRating && question.average != null)
            Row(
              children: [
                Icon(Icons.star_rate_rounded, color: JadalColors.primaryOrange, size: 20),
                const SizedBox(width: 6),
                Text(
                  context.loc.surveyAverageLabel(
                    question.average!.toStringAsFixed(1),
                    '${question.ratingMax}',
                    '${question.totalAnswered}',
                  ),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                  ),
                ),
              ],
            )
          else if (question.isMcq && question.distribution != null)
            _DistributionBars(distribution: question.distribution!, isDark: isDark)
          else if (question.isOpenText && question.textAnswers != null)
            Text(
              context.loc.surveyTextAnswersCount(question.textAnswers!.length),
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: JadalColors.judgesGrey),
            ),
        ],
      ),
    );
  }
}

class _DistributionBars extends StatelessWidget {
  final Map<String, int> distribution;
  final bool isDark;
  const _DistributionBars({required this.distribution, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxCount = distribution.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: distribution.entries.map((entry) {
        final ratio = maxCount > 0 ? entry.value / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor:
                        isDark ? JadalColors.darkSurfaceElevated : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(JadalColors.primaryOrange),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.value}',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: JadalColors.judgesGrey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// One respondent's card: who they are + every answer they gave, matched
/// back to the question text/type via [questions].
class _RespondentCard extends StatelessWidget {
  final SurveyIndividualResponse response;
  final List<SurveyResultsQuestion> questions;
  final bool isDark;

  const _RespondentCard({
    required this.response,
    required this.questions,
    required this.isDark,
  });

  String _formatAnswer(SurveyResultsQuestion q, dynamic value) {
    if (value == null) return '—';
    if (q.isRating) return '$value / ${q.ratingMax}';
    return value.toString();
  }

  String _formatDate(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final respondent = response.respondent;
    final initial = respondent.name.isNotEmpty ? respondent.name[0] : '?';

    return SurveyPanel(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: JadalColors.primaryOrange.withValues(alpha: 0.15),
                backgroundImage:
                    respondent.avatarUrl != null ? NetworkImage(respondent.avatarUrl!) : null,
                child: respondent.avatarUrl == null
                    ? Text(
                        initial,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color: JadalColors.primaryOrange,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      respondent.name,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                      ),
                    ),
                    if (respondent.role != null || response.submittedAt != null)
                      Text(
                        [
                          if (respondent.role != null) respondent.role!,
                          if (response.submittedAt != null) _formatDate(response.submittedAt!),
                        ].join(' • '),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: JadalColors.judgesGrey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...questions.map((q) {
            final value = response.answers[q.id.toString()];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.questionText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: JadalColors.judgesGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatAnswer(q, value),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
