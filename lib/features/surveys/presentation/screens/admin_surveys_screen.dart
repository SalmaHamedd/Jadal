import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/surveys/data/repositories/survey_repository_impl.dart';
import 'package:jadal_app/features/surveys/domain/repositories/survey_repository.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/survey_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/screens/admin_survey_detail_screen.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_card.dart';

/// Admin-only view of all surveys (there's no dedicated `/admin/surveys`
/// list endpoint, so this reuses the general `GET /surveys` list — the same
/// data source the respondent-facing SurveysScreen uses) with access to edit
/// each survey via `PUT /admin/surveys/{id}`.
class AdminSurveysScreen extends StatelessWidget {
  const AdminSurveysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SurveyRepository repository = SurveyRepositoryImpl();

    return BlocProvider(
      create: (_) => SurveyCubit(repository)..loadSurveys(),
      child: Builder(
        builder: (context) {
          return JadalGradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text(
                  'إدارة الاستطلاعات',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              body: BlocBuilder<SurveyCubit, SurveyState>(
                builder: (context, state) {
                  if (state is SurveyLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SurveyLoaded) {
                    final surveys = state.surveys;
                    if (surveys.isEmpty) {
                      return RefreshIndicator(
                        color: JadalColors.primaryOrange,
                        onRefresh: () => context.read<SurveyCubit>().loadSurveys(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'لا توجد استطلاعات حالياً',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                              ),
                            ),
                          ],
                        ),
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
                                  builder: (_) => AdminSurveyDetailScreen(
                                    surveyId: survey.id,
                                    repository: repository,
                                  ),
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: JadalColors.judgesGrey),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ: ${state.message}',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.read<SurveyCubit>().loadSurveys(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: JadalColors.primaryOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
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
