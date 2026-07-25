import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/surveys/data/repositories/survey_repository_impl.dart';
import 'package:jadal_app/features/surveys/domain/repositories/survey_repository.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/survey_details_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/screens/edit_admin_survey_screen.dart';

class AdminSurveyDetailScreen extends StatelessWidget {
  final int surveyId;
  final SurveyRepository? repository;

  const AdminSurveyDetailScreen({super.key, required this.surveyId, this.repository});

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? SurveyRepositoryImpl();

    return BlocProvider(
      create: (_) => SurveyDetailsCubit(repo)..loadSurveyDetails(surveyId),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return JadalGradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text(
                  'تفاصيل الاستطلاع',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                actions: [
                  BlocBuilder<SurveyDetailsCubit, SurveyDetailsState>(
                    builder: (context, state) {
                      if (state is! SurveyDetailsLoaded) return const SizedBox();
                      return IconButton(
                        tooltip: 'تعديل الاستطلاع',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditAdminSurveyScreen(
                                details: state.details,
                                repository: repo,
                              ),
                            ),
                          );
                          if (context.mounted) {
                            context.read<SurveyDetailsCubit>().loadSurveyDetails(surveyId);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
              body: BlocBuilder<SurveyDetailsCubit, SurveyDetailsState>(
                builder: (context, state) {
                  if (state is SurveyDetailsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SurveyDetailsLoaded) {
                    final details = state.details;
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
                          if (details.description.isNotEmpty)
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
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusChip(
                                label: details.isClosed ? 'مغلق' : 'مفتوح',
                                color: details.isClosed
                                    ? JadalColors.judgesGrey
                                    : JadalColors.positiveGreen,
                              ),
                              if (details.closesAt != null)
                                _StatusChip(
                                  label: 'ينتهي في ${_formatDate(details.closesAt!)}',
                                  color: JadalColors.primaryBlue,
                                ),
                              ...details.targetRoles.map(
                                (r) => _StatusChip(label: r, color: JadalColors.primaryOrange),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'الأسئلة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: context.fontSize(16),
                              color: isDark
                                  ? JadalColors.darkTextPrimary
                                  : JadalColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...details.questions.map(
                            (q) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? JadalColors.darkSurface
                                    : JadalColors.lightSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? JadalColors.darkSurfaceElevated
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q.questionText,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? JadalColors.darkTextPrimary
                                          : JadalColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _typeLabel(q.type),
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: JadalColors.judgesGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (details.questions.isEmpty)
                            Text(
                              'لا توجد أسئلة لهذا الاستطلاع بعد',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: JadalColors.judgesGrey,
                              ),
                            ),
                        ],
                      ),
                    );
                  } else if (state is SurveyDetailsError) {
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
                            onPressed: () =>
                                context.read<SurveyDetailsCubit>().loadSurveyDetails(surveyId),
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

  String _typeLabel(String type) {
    switch (type) {
      case 'rating':
        return 'تقييم رقمي';
      case 'mcq':
        return 'اختيار من متعدد';
      case 'open_text':
        return 'إجابة مفتوحة';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
