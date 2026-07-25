import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question_input.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';
import 'package:jadal_app/features/surveys/presentation/cubit/update_trainer_survey_cubit.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_question_editor_list.dart';

/// Edits a trainer-owned survey via `PUT /trainer/surveys/{id}`.
///
/// Only fields the trainer actually touches are sent — untouched fields are
/// omitted so the backend leaves them as-is, per the partial-update contract.
/// The one exception is `title`, which is always sent (it's required and
/// resending the same value is a harmless no-op).
///
/// NOTE: there's no endpoint to read a survey's *current* team assignments,
/// so team IDs here start blank rather than pre-filled. Leaving that section
/// untouched omits `team_ids` entirely (existing assignments stay as they are).
class EditTrainerSurveyScreen extends StatefulWidget {
  final SurveyDetails details;
  final TrainerSurveyRepository repository;

  const EditTrainerSurveyScreen({
    super.key,
    required this.details,
    required this.repository,
  });

  @override
  State<EditTrainerSurveyScreen> createState() => _EditTrainerSurveyScreenState();
}

class _EditTrainerSurveyScreenState extends State<EditTrainerSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _teamIdController = TextEditingController();
  final Set<int> _teamIds = {};
  bool _teamIdsTouched = false;

  late DateTime? _closesAt;
  bool _closesAtTouched = false;

  late List<SurveyQuestionInput> _questions;
  bool _questionsTouched = false;

  late final UpdateTrainerSurveyCubit _cubit;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.details.title);
    _descriptionController = TextEditingController(text: widget.details.description);
    _closesAt = widget.details.closesAt;
    _questions = widget.details.questions.map(SurveyQuestionInput.fromExisting).toList();
    _cubit = UpdateTrainerSurveyCubit(widget.repository);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _teamIdController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _addTeamId() {
    final id = int.tryParse(_teamIdController.text.trim());
    if (id == null) {
      JadalSnackBar.show(context, 'أدخل رقم فريق صالح', type: SnackBarType.warning);
      return;
    }
    setState(() {
      _teamIds.add(id);
      _teamIdsTouched = true;
      _teamIdController.clear();
    });
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
      _closesAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _closesAtTouched = true;
    });
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_questionsTouched && _questions.isEmpty) {
      JadalSnackBar.show(
        context,
        'أضف سؤالاً واحداً على الأقل أو تراجع عن تعديل الأسئلة',
        type: SnackBarType.warning,
      );
      return;
    }
    final cleanedQuestions = _questions.map((q) => q.cleaned).toList();
    for (final q in cleanedQuestions) {
      if (q.questionText.isEmpty) {
        JadalSnackBar.show(context, 'أكمل نص كل الأسئلة قبل الحفظ', type: SnackBarType.warning);
        return;
      }
      if (q.type == 'mcq' && q.mcqOptions.length < 2) {
        JadalSnackBar.show(
          context,
          'أسئلة الاختيار من متعدد تحتاج خيارين على الأقل',
          type: SnackBarType.warning,
        );
        return;
      }
    }

    final originalDescription = widget.details.description;
    final currentDescription = _descriptionController.text.trim();
    String? descriptionToSend;
    bool clearDescription = false;
    if (currentDescription != originalDescription) {
      if (currentDescription.isEmpty) {
        clearDescription = true;
      } else {
        descriptionToSend = currentDescription;
      }
    }

    context.read<UpdateTrainerSurveyCubit>().submit(
          id: widget.details.id,
          title: _titleController.text.trim(),
          description: descriptionToSend,
          clearDescription: clearDescription,
          closesAt: _closesAtTouched ? _closesAt : null,
          clearClosesAt: _closesAtTouched && _closesAt == null,
          teamIds: _teamIdsTouched ? _teamIds.toList() : null,
          questions: _questionsTouched ? cleanedQuestions : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UpdateTrainerSurveyCubit>.value(
      value: _cubit,
      child: JadalGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'تعديل الاستطلاع',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: BlocConsumer<UpdateTrainerSurveyCubit, UpdateTrainerSurveyState>(
            listener: (context, state) {
              if (state is UpdateTrainerSurveySuccess) {
                JadalSnackBar.show(context, 'تم تحديث الاستطلاع بنجاح', type: SnackBarType.success);
                Navigator.pop(context, state.details);
              } else if (state is UpdateTrainerSurveyError) {
                JadalSnackBar.show(context, state.message, type: SnackBarType.error);
              }
            },
            builder: (context, state) {
              final submitting = state is UpdateTrainerSurveySubmitting;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return SingleChildScrollView(
                padding: EdgeInsets.all(context.wp(5)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthTextField(
                        label: 'عنوان الاستطلاع',
                        icon: Icons.title,
                        controller: _titleController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                      ),
                      SizedBox(height: context.hp(2)),
                      AuthTextField(
                        label: 'الوصف (اضبطه فارغاً لحذفه)',
                        icon: Icons.description_outlined,
                        controller: _descriptionController,
                        textInputAction: TextInputAction.newline,
                      ),
                      SizedBox(height: context.hp(2.5)),
                      Text(
                        'الفرق (اختياري)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _teamIdsTouched
                            ? 'سيتم استبدال الفرق المعيّنة بهذه القائمة بالكامل'
                            : 'اتركها كما هي للإبقاء على تعيينات الفرق الحالية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: JadalColors.judgesGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              label: 'رقم الفريق',
                              icon: Icons.groups_outlined,
                              controller: _teamIdController,
                              keyboardType: TextInputType.number,
                              onSubmitted: (_) => _addTeamId(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: JadalColors.primaryOrange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _addTeamId,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      if (_teamIdsTouched) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._teamIds.map(
                              (id) => Chip(
                                label: Text(
                                  'فريق #$id',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                                backgroundColor:
                                    JadalColors.primaryOrange.withValues(alpha: 0.12),
                                onDeleted: () => setState(() => _teamIds.remove(id)),
                              ),
                            ),
                            ActionChip(
                              label: const Text(
                                'تراجع عن تعديل الفرق',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                              ),
                              onPressed: () => setState(() {
                                _teamIdsTouched = false;
                                _teamIds.clear();
                              }),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: context.hp(2.5)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'موعد الإغلاق',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? JadalColors.darkTextPrimary
                                    : JadalColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          if (_closesAtTouched)
                            TextButton(
                              onPressed: () => setState(() {
                                _closesAtTouched = false;
                                _closesAt = widget.details.closesAt;
                              }),
                              child: const Text(
                                'تراجع',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _pickClosesAt(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? JadalColors.darkSurfaceElevated
                                : const Color(0xFFF1F4F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event_outlined, size: 20, color: JadalColors.judgesGrey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _closesAt != null
                                      ? _formatDateTime(_closesAt!)
                                      : 'بدون موعد إغلاق',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: isDark
                                        ? JadalColors.darkTextPrimary
                                        : JadalColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              if (_closesAt != null)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() {
                                    _closesAt = null;
                                    _closesAtTouched = true;
                                  }),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: context.hp(2.5)),
                      Text(
                        'الأسئلة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'أي تعديل هنا يستبدل كل أسئلة الاستطلاع الحالية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: JadalColors.judgesGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SurveyQuestionEditorList(
                        questions: _questions,
                        onChanged: (qs) => setState(() {
                          _questions = qs;
                          _questionsTouched = true;
                        }),
                      ),
                      SizedBox(height: context.hp(3)),
                      AuthButton(
                        text: 'حفظ التعديلات',
                        isLoading: submitting,
                        onPressed: submitting ? null : () => _submit(context),
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
