import 'package:flutter/material.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question.dart';
import 'package:jadal_app/features/surveys/presentation/widgets/survey_panel.dart';

/// Renders the right input for a survey question (rating / mcq / open_text)
/// and reports the current answer via [onChanged].
class SurveyQuestionField extends StatefulWidget {
  final int index;
  final SurveyQuestion question;
  final dynamic initialValue;
  final ValueChanged<dynamic> onChanged;

  const SurveyQuestionField({
    super.key,
    required this.index,
    required this.question,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<SurveyQuestionField> createState() => _SurveyQuestionFieldState();
}

class _SurveyQuestionFieldState extends State<SurveyQuestionField> {
  late int _ratingValue;
  String? _selectedOption;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _ratingValue = (widget.initialValue is int)
        ? widget.initialValue
        : widget.question.ratingMin;
    _selectedOption = widget.initialValue is String ? widget.initialValue : null;
    _textController = TextEditingController(
      text: widget.initialValue is String ? widget.initialValue : '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = widget.question;

    return SurveyPanel(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.index}. ${q.questionText}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: context.fontSize(15),
              color: isDark
                  ? JadalColors.darkTextPrimary
                  : JadalColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (q.isRating) _buildRating(isDark),
          if (q.isMcq) _buildMcq(isDark),
          if (q.isOpenText) _buildOpenText(isDark),
        ],
      ),
    );
  }

  Widget _buildRating(bool isDark) {
    final q = widget.question;
    return Column(
      children: [
        Slider(
          value: _ratingValue.clamp(q.ratingMin, q.ratingMax).toDouble(),
          min: q.ratingMin.toDouble(),
          max: q.ratingMax.toDouble(),
          divisions: q.ratingStep > 0
              ? ((q.ratingMax - q.ratingMin) / q.ratingStep).round()
              : null,
          activeColor: JadalColors.primaryOrange,
          label: '$_ratingValue',
          onChanged: (value) {
            setState(() => _ratingValue = value.round());
            widget.onChanged(_ratingValue);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${q.ratingMin}', style: TextStyle(color: JadalColors.judgesGrey)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: JadalColors.primaryOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_ratingValue',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  color: JadalColors.primaryOrange,
                ),
              ),
            ),
            Text('${q.ratingMax}', style: TextStyle(color: JadalColors.judgesGrey)),
          ],
        ),
      ],
    );
  }

  Widget _buildMcq(bool isDark) {
    final options = widget.question.mcqOptions;
    return Column(
      children: options.map((option) {
        final selected = _selectedOption == option;
        return RadioListTile<String>(
          value: option,
          groupValue: _selectedOption,
          contentPadding: EdgeInsets.zero,
          activeColor: JadalColors.primaryOrange,
          title: Text(
            option,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: isDark
                  ? JadalColors.darkTextPrimary
                  : JadalColors.lightTextPrimary,
            ),
          ),
          onChanged: (value) {
            setState(() => _selectedOption = value);
            widget.onChanged(value);
          },
        );
      }).toList(),
    );
  }

  Widget _buildOpenText(bool isDark) {
    return TextField(
      controller: _textController,
      maxLines: 3,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontFamily: 'Cairo',
        color: isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: context.loc.surveyWriteAnswerHint,
        hintStyle: TextStyle(fontFamily: 'Cairo', color: JadalColors.judgesGrey),
        filled: true,
        fillColor: isDark ? JadalColors.darkSurfaceElevated : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
