import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question_input.dart';

/// Editable list of [SurveyQuestionInput] drafts, used by both the admin and
/// trainer "edit survey" screens to build the `questions` array for a
/// full-replace PUT request.
class SurveyQuestionEditorList extends StatelessWidget {
  final List<SurveyQuestionInput> questions;
  final ValueChanged<List<SurveyQuestionInput>> onChanged;

  const SurveyQuestionEditorList({
    super.key,
    required this.questions,
    required this.onChanged,
  });

  void _update(int index, SurveyQuestionInput q) {
    final next = [...questions];
    next[index] = q;
    onChanged(next);
  }

  void _remove(int index) {
    final next = [...questions]..removeAt(index);
    final reindexed = [for (var i = 0; i < next.length; i++) next[i].copyWith(orderIndex: i)];
    onChanged(reindexed);
  }

  void _add() {
    onChanged([
      ...questions,
      SurveyQuestionInput(questionText: '', type: 'rating', orderIndex: questions.length),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...questions.asMap().entries.map(
              (entry) => _QuestionEditorCard(
                key: ValueKey('survey_question_draft_${entry.key}'),
                index: entry.key,
                question: entry.value,
                isDark: isDark,
                onChanged: (q) => _update(entry.key, q),
                onRemove: () => _remove(entry.key),
              ),
            ),
        OutlinedButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: Text(context.loc.surveyAddQuestion, style: const TextStyle(fontFamily: 'Cairo')),
          style: OutlinedButton.styleFrom(
            foregroundColor: JadalColors.primaryOrange,
            side: BorderSide(color: JadalColors.primaryOrange),
          ),
        ),
      ],
    );
  }
}

class _QuestionEditorCard extends StatefulWidget {
  final int index;
  final SurveyQuestionInput question;
  final bool isDark;
  final ValueChanged<SurveyQuestionInput> onChanged;
  final VoidCallback onRemove;

  const _QuestionEditorCard({
    super.key,
    required this.index,
    required this.question,
    required this.isDark,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_QuestionEditorCard> createState() => _QuestionEditorCardState();
}

class _QuestionEditorCardState extends State<_QuestionEditorCard> {
  late final TextEditingController _textController;
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question.questionText);
    _optionControllers = widget.question.mcqOptions
        .map((o) => TextEditingController(text: o))
        .toList();
    if (widget.question.type == 'mcq' && _optionControllers.length < 2) {
      while (_optionControllers.length < 2) {
        _optionControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.question.copyWith(
        questionText: _textController.text,
        mcqOptions: _optionControllers.map((c) => c.text).toList(),
      ),
    );
  }

  void _changeType(String? type) {
    if (type == null) return;
    setState(() {
      if (type == 'mcq' && _optionControllers.isEmpty) {
        _optionControllers = [TextEditingController(), TextEditingController()];
      }
    });
    widget.onChanged(widget.question.copyWith(type: type));
  }

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
    _emit();
  }

  void _removeOption(int i) {
    setState(() {
      _optionControllers.removeAt(i).dispose();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final q = widget.question;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? JadalColors.darkSurfaceElevated : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.loc.surveyQuestionNumber(widget.index + 1),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: JadalColors.judgesGrey),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          TextField(
            controller: _textController,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: context.loc.surveyQuestionTextHint,
              hintStyle: TextStyle(fontFamily: 'Cairo', color: JadalColors.judgesGrey),
              filled: true,
              fillColor: isDark ? JadalColors.darkSurfaceElevated : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: q.type,
            decoration: InputDecoration(
              labelText: context.loc.surveyQuestionTypeLabel,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              filled: true,
              fillColor: isDark ? JadalColors.darkSurfaceElevated : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            items: [
              DropdownMenuItem(value: 'rating', child: Text(context.loc.surveyTypeRating)),
              DropdownMenuItem(value: 'mcq', child: Text(context.loc.surveyTypeMcq)),
              DropdownMenuItem(value: 'open_text', child: Text(context.loc.surveyTypeOpenText)),
            ],
            onChanged: _changeType,
          ),
          if (q.type == 'rating') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: context.loc.surveyMinValue,
                    value: q.ratingMin,
                    onChanged: (v) => widget.onChanged(q.copyWith(ratingMin: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: context.loc.surveyMaxValue,
                    value: q.ratingMax,
                    onChanged: (v) => widget.onChanged(q.copyWith(ratingMax: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: context.loc.surveyStepValue,
                    value: q.ratingStep,
                    onChanged: (v) => widget.onChanged(q.copyWith(ratingStep: v)),
                  ),
                ),
              ],
            ),
          ],
          if (q.type == 'mcq') ...[
            const SizedBox(height: 10),
            Text(
              context.loc.surveyOptionsMinTwo,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: JadalColors.judgesGrey),
            ),
            const SizedBox(height: 6),
            ..._optionControllers.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: e.value,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: isDark
                                  ? JadalColors.darkTextPrimary
                                  : JadalColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: context.loc.surveyOptionHint(e.key + 1),
                              filled: true,
                              fillColor:
                                  isDark ? JadalColors.darkSurfaceElevated : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                            onChanged: (_) => _emit(),
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeOption(e.key),
                          ),
                      ],
                    ),
                  ),
                ),
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.loc.surveyAddOption, style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _NumberField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: '$value',
      keyboardType: TextInputType.number,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}
