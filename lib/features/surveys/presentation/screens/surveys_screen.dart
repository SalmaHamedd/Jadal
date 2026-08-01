import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/surveys/data/repositories/survey_repository_impl.dart';
import 'package:jadal_app/features/surveys/domain/repositories/survey_repository.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/survey_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/screens/survey_details_screen.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_card.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_state_views.dart';

class SurveysScreen extends StatelessWidget {
  const SurveysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return JadalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            context.loc.drawerSurveys,
            style: AppTextStyles.title(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: BlocProvider(
          create: (_) {
            final SurveyRepository repository = SurveyRepositoryImpl();
            return SurveyCubit(repository)..loadSurveys();
          },
          child: BlocBuilder<SurveyCubit, SurveyState>(
            builder: (context, state) {
              if (state is SurveyLoading) {
                return const SurveyLoadingView();
              } else if (state is SurveyLoaded) {
                final surveys = state.surveys;
                if (surveys.isEmpty) {
                  return SurveyEmptyState(
                    message: context.loc.surveyNoneAvailable,
                    onRefresh: () => context.read<SurveyCubit>().loadSurveys(),
                  );
                }
                return RefreshIndicator(
                  color: JadalColors.primaryOrange,
                  onRefresh: () => context.read<SurveyCubit>().loadSurveys(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: surveys.length,
                    itemBuilder: (context, index) {
                      final survey = surveys[index];
                      return SurveyCard(
                        survey: survey,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SurveyDetailsScreen(surveyId: survey.id),
                            ),
                          );
                          if (context.mounted) {
                            context.read<SurveyCubit>().loadSurveys();
                          }
                        },
                      );
                    },
                  ),
                );
              } else if (state is SurveyError) {
                return SurveyErrorView(
                  message: state.message,
                  onRetry: () => context.read<SurveyCubit>().loadSurveys(),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}
