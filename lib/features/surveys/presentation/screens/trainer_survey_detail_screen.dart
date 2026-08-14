import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/surveys/data/repositories/trainer_survey_repository_impl.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/delete_trainer_survey_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/trainer_survey_details_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/screens/trainer_survey_results_screen.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_panel.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_state_views.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_status_chip.dart';
import 'package:jadal_app/core/error/failure_text.dart';

class TrainerSurveyDetailScreen extends StatelessWidget {
  final int surveyId;
  final TrainerSurveyRepository? repository;

  const TrainerSurveyDetailScreen({
    super.key,
    required this.surveyId,
    this.repository,
  });

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.loc.surveyDeleteTitle,
          style: AppTextStyles.subtitle(context),
        ),
        content: Text(
          context.loc.surveyDeleteConfirmBody,
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.loc.cancel,
              style: AppTextStyles.button(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.loc.delete,
              style: AppTextStyles.button(context).copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? TrainerSurveyRepositoryImpl();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              TrainerSurveyDetailsCubit(repo)..loadSurveyDetails(surveyId),
        ),
        BlocProvider(create: (_) => DeleteTrainerSurveyCubit(repo)),
      ],
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return BlocListener<
            DeleteTrainerSurveyCubit,
            DeleteTrainerSurveyState
          >(
            listener: (context, state) {
              if (state is DeleteTrainerSurveySuccess) {
                JadalSnackBar.show(
                  context,
                  context.loc.surveyDeletedMsg,
                  type: SnackBarType.success,
                );
                Navigator.pop(context, true);
              } else if (state is DeleteTrainerSurveyError) {
                JadalSnackBar.show(
                  context, FailureText.fromMessage(context, state.message),
                  type: SnackBarType.error,
                );
              }
            },
            child: JadalGradientBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(
                    context.loc.surveyDetailsHeaderTitle,
                    style: AppTextStyles.title(context),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  actions: [
                    BlocBuilder<
                      TrainerSurveyDetailsCubit,
                      TrainerSurveyDetailsState
                    >(
                      builder: (context, state) {
                        if (state is! TrainerSurveyDetailsLoaded)
                          return const SizedBox();
                        return IconButton(
                          tooltip: context.loc.viewResults,
                          icon: const Icon(Icons.bar_chart_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrainerSurveyResultsScreen(
                                  surveyId: surveyId,
                                  repository: repo,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    BlocBuilder<
                      DeleteTrainerSurveyCubit,
                      DeleteTrainerSurveyState
                    >(
                      builder: (context, state) {
                        final deleting = state is DeleteTrainerSurveyDeleting;
                        return IconButton(
                          tooltip: context.loc.surveyDeleteTitle,
                          icon: deleting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                          onPressed: deleting
                              ? null
                              : () async {
                                  final confirmed = await _confirmDelete(
                                    context,
                                  );
                                  if (confirmed && context.mounted) {
                                    context
                                        .read<DeleteTrainerSurveyCubit>()
                                        .deleteSurvey(surveyId);
                                  }
                                },
                        );
                      },
                    ),
                  ],
                ),
                body:
                    BlocBuilder<
                      TrainerSurveyDetailsCubit,
                      TrainerSurveyDetailsState
                    >(
                      builder: (context, state) {
                        if (state is TrainerSurveyDetailsLoading) {
                          return const SurveyLoadingView();
                        } else if (state is TrainerSurveyDetailsLoaded) {
                          final details = state.details;
                          return SingleChildScrollView(
                            padding: EdgeInsets.all(
                              context.wp(5),
                            ).copyWith(bottom: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  details.title,
                                  style: AppTextStyles.displayTitle(context)
                                      .copyWith(
                                        color: isDark
                                            ? JadalColors.darkTextPrimary
                                            : JadalColors.lightTextPrimary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                if (details.description.isNotEmpty)
                                  Text(
                                    details.description,
                                    style: AppTextStyles.body(context).copyWith(
                                      height: 1.6,
                                      color: isDark
                                          ? JadalColors.darkTextSecondary
                                          : JadalColors.lightTextSecondary,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    SurveyStatusChip(
                                      label: details.isClosed
                                          ? context.loc.surveyStatusClosed
                                          : context.loc.surveyStatusOpen,
                                      color: details.isClosed
                                          ? JadalColors.judgesGrey
                                          : JadalColors.positiveGreen,
                                    ),
                                    if (details.closesAt != null)
                                      SurveyStatusChip(
                                        label: context.loc.surveyClosesOnDate(
                                          _formatDate(details.closesAt!),
                                        ),
                                        color: JadalColors.primaryBlue,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  context.loc.surveyQuestionsHeader,
                                  style: AppTextStyles.subtitle(context)
                                      .copyWith(
                                        color: isDark
                                            ? JadalColors.darkTextPrimary
                                            : JadalColors.lightTextPrimary,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                ...details.questions.map(
                                  (q) => SurveyPanel(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          q.questionText,
                                          style: AppTextStyles.body(context)
                                              .copyWith(
                                                color: isDark
                                                    ? JadalColors
                                                          .darkTextPrimary
                                                    : JadalColors
                                                          .lightTextPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _typeLabel(context, q.type),
                                          style: AppTextStyles.caption(context)
                                              .copyWith(
                                                color: JadalColors.judgesGrey,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (details.questions.isEmpty)
                                  Text(
                                    context.loc.surveyNoQuestionsYet,
                                    style: AppTextStyles.body(
                                      context,
                                    ).copyWith(color: JadalColors.judgesGrey),
                                  ),
                              ],
                            ),
                          );
                        } else if (state is TrainerSurveyDetailsError) {
                          return SurveyErrorView(
                            message: state.message,
                            onRetry: () => context
                                .read<TrainerSurveyDetailsCubit>()
                                .loadSurveyDetails(surveyId),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _typeLabel(BuildContext context, String type) {
    switch (type) {
      case 'rating':
        return context.loc.surveyTypeRating;
      case 'mcq':
        return context.loc.surveyTypeMcq;
      case 'open_text':
        return context.loc.surveyTypeOpenText;
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
