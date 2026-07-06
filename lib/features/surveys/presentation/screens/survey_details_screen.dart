import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/surveys/data/repositories/survey_repository_impl.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';
import 'package:jadal_app/features/surveys/domain/repositories/survey_repository.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/survey_details_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/survey_response_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_question_field.dart';

class SurveyDetailsScreen extends StatefulWidget {
  final int surveyId;
  const SurveyDetailsScreen({super.key, required this.surveyId});

  @override
  State<SurveyDetailsScreen> createState() => _SurveyDetailsScreenState();
}

class _SurveyDetailsScreenState extends State<SurveyDetailsScreen> {
  late final SurveyRepository _repository;
  final Map<int, dynamic> _answers = {};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _repository = SurveyRepositoryImpl();
  }

  bool _allAnswered(SurveyDetails details) {
    for (final q in details.questions) {
      final value = _answers[q.id];
      if (value == null) return false;
      if (value is String && value.trim().isEmpty) return false;
    }
    return true;
  }

  void _submit(BuildContext context, SurveyDetails details) {
    if (!_allAnswered(details)) {
      JadalSnackBar.show(
        context,
        'يرجى الإجابة على جميع الأسئلة قبل الإرسال',
        type: SnackBarType.warning,
      );
      return;
    }
    final answers = _answers.map((key, value) => MapEntry(key.toString(), value));
    context.read<SurveyResponseCubit>().submitResponse(
          surveyId: details.id,
          answers: answers,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider<SurveyDetailsCubit>(
          create: (_) =>
              SurveyDetailsCubit(_repository)..loadSurveyDetails(widget.surveyId),
        ),
        BlocProvider<SurveyResponseCubit>(
          create: (_) => SurveyResponseCubit(_repository),
        ),
      ],
      child: JadalGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'الاستطلاع',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: BlocConsumer<SurveyResponseCubit, SurveyResponseState>(
            listener: (context, state) {
              if (state is SurveyResponseSuccess) {
                setState(() => _submitted = true);
                JadalSnackBar.show(
                  context,
                  'تم تقديم إجاباتك بنجاح',
                  type: SnackBarType.success,
                );
              } else if (state is SurveyResponseError) {
                JadalSnackBar.show(context, state.message, type: SnackBarType.error);
              }
            },
            builder: (context, responseState) {
              return BlocBuilder<SurveyDetailsCubit, SurveyDetailsState>(
                builder: (context, detailsState) {
                  if (detailsState is SurveyDetailsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (detailsState is SurveyDetailsLoaded) {
                    final details = detailsState.details;
                    final locked = details.isClosed || details.alreadyResponded || _submitted;
                    final submitting = responseState is SurveyResponseSubmitting;

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(context.wp(5)).copyWith(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details.title,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: context.fontSize(22, min: 18, max: 26),
                              color: isDark
                                  ? JadalColors.darkTextPrimary
                                  : JadalColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            details.description,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: context.fontSize(14),
                              height: 1.6,
                              color: isDark
                                  ? JadalColors.darkTextSecondary
                                  : JadalColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (locked) _buildLockedBanner(details, isDark),
                          if (locked) const SizedBox(height: 20),
                          ...details.questions.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final question = entry.value;
                            return IgnorePointer(
                              ignoring: locked,
                              child: Opacity(
                                opacity: locked ? 0.5 : 1,
                                child: SurveyQuestionField(
                                  index: index,
                                  question: question,
                                  onChanged: (value) => _answers[question.id] = value,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          if (!locked)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: submitting
                                    ? null
                                    : () => _submit(context, details),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: JadalColors.primaryOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'إرسال الإجابات',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    );
                  } else if (detailsState is SurveyDetailsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: JadalColors.judgesGrey),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ: ${detailsState.message}',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context
                                .read<SurveyDetailsCubit>()
                                .loadSurveyDetails(widget.surveyId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: JadalColors.primaryOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLockedBanner(SurveyDetails details, bool isDark) {
    final String message;
    final IconData icon;
    final Color color;

    if (_submitted || details.alreadyResponded) {
      message = 'لقد قمت بالإجابة على هذا الاستطلاع من قبل';
      icon = Icons.check_circle_outline;
      color = JadalColors.positiveGreen;
    } else {
      message = 'هذا الاستطلاع مغلق ولا يقبل إجابات جديدة';
      icon = Icons.lock_clock_outlined;
      color = JadalColors.judgesGrey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
