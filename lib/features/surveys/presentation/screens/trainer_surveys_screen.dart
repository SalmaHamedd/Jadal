import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/surveys/data/repositories/trainer_survey_repository_impl.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/trainer_survey_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/screens/create_trainer_survey_screen.dart';
import 'package:jadal_app/features/surveys/presentation/screens/trainer_survey_detail_screen.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_card.dart';

class TrainerSurveysScreen extends StatelessWidget {
  const TrainerSurveysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TrainerSurveyRepository repository = TrainerSurveyRepositoryImpl();

    return BlocProvider(
      create: (_) => TrainerSurveyCubit(repository)..loadSurveys(),
      child: Builder(
        builder: (context) {
          return JadalGradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text(
                  'استطلاعات فريقي',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: JadalColors.primaryOrange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text(
                  'استطلاع جديد',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                ),
                onPressed: () async {
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateTrainerSurveyScreen(repository: repository),
                    ),
                  );
                  if (created == true && context.mounted) {
                    context.read<TrainerSurveyCubit>().loadSurveys();
                  }
                },
              ),
              body: BlocBuilder<TrainerSurveyCubit, TrainerSurveyState>(
                builder: (context, state) {
                  if (state is TrainerSurveyLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TrainerSurveyLoaded) {
                    final surveys = state.surveys;
                    if (surveys.isEmpty) {
                      return RefreshIndicator(
                        color: JadalColors.primaryOrange,
                        onRefresh: () => context.read<TrainerSurveyCubit>().loadSurveys(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'لم تنشئ أي استطلاعات لفريقك بعد',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: JadalColors.primaryOrange,
                      onRefresh: () => context.read<TrainerSurveyCubit>().loadSurveys(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: surveys.length,
                        itemBuilder: (context, index) {
                          final survey = surveys[index];
                          return SurveyCard(
                            survey: survey,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrainerSurveyDetailScreen(
                                    surveyId: survey.id,
                                    repository: repository,
                                  ),
                                ),
                              );
                              if (context.mounted) {
                                context.read<TrainerSurveyCubit>().loadSurveys();
                              }
                            },
                          );
                        },
                      ),
                    );
                  } else if (state is TrainerSurveyError) {
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
                            onPressed: () => context.read<TrainerSurveyCubit>().loadSurveys(),
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
