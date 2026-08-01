import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question_input.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/create_trainer_survey_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_question_editor_list.dart';
import 'package:jadal_app/features/teams/presentation/widgets/team_picker_field.dart';

/// Creates a new survey for the trainer's own team(s).
///
/// The `POST /trainer/surveys` endpoint itself only accepts title/description/
/// team_ids/closes_at (no questions), so questions typed in here are attached
/// with a follow-up `PUT` call right after creation succeeds — from the
/// trainer's point of view it's one step.
class CreateTrainerSurveyScreen extends StatefulWidget {
  final TrainerSurveyRepository repository;
  const CreateTrainerSurveyScreen({super.key, required this.repository});

  @override
  State<CreateTrainerSurveyScreen> createState() =>
      _CreateTrainerSurveyScreenState();
}

class _CreateTrainerSurveyScreenState extends State<CreateTrainerSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<int> _teamIds = {};
  DateTime? _closesAt;
  List<SurveyQuestionInput> _questions = [
    const SurveyQuestionInput(questionText: '', type: 'rating', orderIndex: 0),
  ];
  late final CreateTrainerSurveyCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = CreateTrainerSurveyCubit(widget.repository);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickClosesAt(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _closesAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_closesAt ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _closesAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_teamIds.isEmpty) {
      JadalSnackBar.show(
        context,
        context.loc.surveyAddAtLeastOneTeam,
        type: SnackBarType.warning,
      );
      return;
    }
    if (_questions.isEmpty) {
      JadalSnackBar.show(
        context,
        context.loc.surveyAddAtLeastOneQuestion,
        type: SnackBarType.warning,
      );
      return;
    }
    final cleanedQuestions = _questions.map((q) => q.cleaned).toList();
    for (final q in cleanedQuestions) {
      if (q.questionText.isEmpty) {
        JadalSnackBar.show(
          context,
          context.loc.surveyCompleteAllQuestionText,
          type: SnackBarType.warning,
        );
        return;
      }
      if (q.type == 'mcq' && q.mcqOptions.length < 2) {
        JadalSnackBar.show(
          context,
          context.loc.surveyMcqNeedsTwoOptions,
          type: SnackBarType.warning,
        );
        return;
      }
    }
    context.read<CreateTrainerSurveyCubit>().submit(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      teamIds: _teamIds.toList(),
      closesAt: _closesAt,
      questions: cleanedQuestions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateTrainerSurveyCubit>.value(
      value: _cubit,
      child: JadalGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              context.loc.surveyNewSurvey,
              style: AppTextStyles.title(context),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body:
              BlocConsumer<CreateTrainerSurveyCubit, CreateTrainerSurveyState>(
                listener: (context, state) {
                  if (state is CreateTrainerSurveySuccess) {
                    JadalSnackBar.show(
                      context,
                      context.loc.surveyCreatedSuccess,
                      type: SnackBarType.success,
                    );
                    Navigator.pop(context, true);
                  } else if (state is CreateTrainerSurveyPartialSuccess) {
                    JadalSnackBar.show(
                      context,
                      context.loc.surveyPartialSuccess(state.message),
                      type: SnackBarType.error,
                    );
                  } else if (state is CreateTrainerSurveyError) {
                    JadalSnackBar.show(
                      context,
                      state.message,
                      type: SnackBarType.error,
                    );
                  }
                },
                builder: (context, state) {
                  final submitting = state is CreateTrainerSurveySubmitting;
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(context.wp(5)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthTextField(
                            label: context.loc.surveyTitleField,
                            icon: Icons.title,
                            controller: _titleController,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? context.loc.surveyTitleRequired
                                : null,
                          ),
                          SizedBox(height: context.hp(2)),
                          AuthTextField(
                            label: context.loc.surveyDescriptionOptional,
                            icon: Icons.description_outlined,
                            controller: _descriptionController,
                            textInputAction: TextInputAction.newline,
                          ),
                          SizedBox(height: context.hp(2.5)),
                          Text(
                            context.loc.surveyTargetTeams,
                            style: AppTextStyles.bodyEmphasis(context).copyWith(
                              color: isDark
                                  ? JadalColors.darkTextPrimary
                                  : JadalColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.loc.surveyChooseAtLeastOneTeam,
                            style: AppTextStyles.caption(
                              context,
                            ).copyWith(color: JadalColors.judgesGrey),
                          ),
                          const SizedBox(height: 10),
                          TeamPickerField(
                            selectedIds: _teamIds,
                            onChanged: (ids) => setState(() {
                              _teamIds
                                ..clear()
                                ..addAll(ids);
                            }),
                          ),
                          SizedBox(height: context.hp(2.5)),
                          Text(
                            context.loc.surveyCloseDateOptional,
                            style: AppTextStyles.bodyEmphasis(context).copyWith(
                              color: isDark
                                  ? JadalColors.darkTextPrimary
                                  : JadalColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _pickClosesAt(context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? JadalColors.darkSurfaceElevated
                                    : const Color(0xFFF1F4F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_outlined,
                                    size: 20,
                                    color: JadalColors.judgesGrey,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _closesAt != null
                                          ? _formatDateTime(_closesAt!)
                                          : context.loc.surveyNoCloseDate,
                                      style: AppTextStyles.body(context)
                                          .copyWith(
                                            color: isDark
                                                ? JadalColors.darkTextPrimary
                                                : JadalColors.lightTextPrimary,
                                          ),
                                    ),
                                  ),
                                  if (_closesAt != null)
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () =>
                                          setState(() => _closesAt = null),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: context.hp(2.5)),
                          Text(
                            context.loc.surveyQuestionsRequiredLabel,
                            style: AppTextStyles.bodyEmphasis(context).copyWith(
                              color: isDark
                                  ? JadalColors.darkTextPrimary
                                  : JadalColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.loc.surveyQuestionsHint,
                            style: AppTextStyles.caption(
                              context,
                            ).copyWith(color: JadalColors.judgesGrey),
                          ),
                          const SizedBox(height: 10),
                          SurveyQuestionEditorList(
                            questions: _questions,
                            onChanged: (qs) => setState(() => _questions = qs),
                          ),
                          SizedBox(height: context.hp(4)),
                          AuthButton(
                            text: context.loc.surveyCreateButton,
                            isLoading: submitting,
                            onPressed: submitting
                                ? null
                                : () => _submit(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}
