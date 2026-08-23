import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../../data/models/debate_models.dart';
import '../../domain/debate_result_view.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';
import '../../../../core/error/failure_text.dart';

/// The chair's result-submit UI: a winning-side picker, one **integer
/// 0–100** score slider per speech (from [DebateController.scoreableStages]) and
/// free-text notes. On submit it calls [DebateController.submitResult] and pops
/// with `true` **only when the backend actually accepted it** — on failure
/// it stays open and shows the server's message.
class ResultSubmitSheet extends StatefulWidget {
  final DebateController controller;
  const ResultSubmitSheet({super.key, required this.controller});

  static Future<bool?> show(BuildContext context, DebateController controller) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DebateTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ResultSubmitSheet(controller: controller),
    );
  }

  @override
  State<ResultSubmitSheet> createState() => _ResultSubmitSheetState();
}

class _ResultSubmitSheetState extends State<ResultSubmitSheet> {
  late final List<ResultStageRef> _stages;
  // Scores are plain INTEGERS 0–100 for every stage (incl. reply) — no
  // 59–90 / reply-halving / 0.5 steps (the backend validator rejects decimals).
  final Map<int, int> _scores = {};
  static const int _defaultScore = 75;
  final TextEditingController _notes = TextEditingController();
  DebateSide? _winning;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _stages = widget.controller.scoreableStages;
    for (final s in _stages) {
      _scores[s.stageOrder] = _defaultScore;
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = context.loc;
    if (_winning == null) {
      JadalSnackBar.show(context, FailureText.fromMessage(context, loc.selectWinningSideFirst), type: SnackBarType.error);
      return;
    }
    setState(() => _submitting = true);
    // Honest submit — only treat it as success if the backend accepted it.
    final ok = await widget.controller.submitResult(
      winningSide: _winning!,
      scoresByStageOrder: _scores.map<int, num>((k, v) => MapEntry(k, v)),
      summaryNotes: _notes.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // Failed: stay open so the chair can fix + retry. The exact server message
      // is shown by the DebateErrorState listener wrapping this sheet.
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    // Surface the backend's real rejection message (e.g. an integer-score
    // validation error) and keep the sheet open instead of faking success.
    return BlocListener<DebateController, DebateStates>(
      bloc: widget.controller,
      listenWhen: (_, s) => s is DebateErrorState,
      listener: (ctx, s) {
        if (s is DebateErrorState) {
          JadalSnackBar.show(ctx, FailureText.fromMessage(ctx, s.message), type: SnackBarType.error);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: DebateTheme.textSecondary(context).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.submitResultTitle,
                style: AppTextStyles.headline(context)
                    .copyWith(fontWeight: FontWeight.w900, color: DebateTheme.textPrimary(context)),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  loc.submitResultPrompt,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(context)
                      .copyWith(color: DebateTheme.textSecondary(context)),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  children: [
                    _label(context, loc.winningSideLabel),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SideButton(
                            label: loc.proposition,
                            side: DebateSide.proposition,
                            selected: _winning == DebateSide.proposition,
                            onTap: () => setState(() => _winning = DebateSide.proposition),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SideButton(
                            label: loc.opposition,
                            side: DebateSide.opposition,
                            selected: _winning == DebateSide.opposition,
                            onTap: () => setState(() => _winning = DebateSide.opposition),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _label(context, loc.perSpeechScores),
                    const SizedBox(height: 4),
                    for (final s in _stages) _StageSlider(
                      stage: s,
                      value: _scores[s.stageOrder] ?? _defaultScore,
                      onChanged: (v) => setState(() => _scores[s.stageOrder] = v),
                    ),
                    const SizedBox(height: 14),
                    _label(context, loc.summaryNotesLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      style: AppTextStyles.body(context)
                          .copyWith(color: DebateTheme.textPrimary(context)),
                      decoration: InputDecoration(
                        hintText: loc.summaryNotesHint,
                        hintStyle: AppTextStyles.body(context)
                            .copyWith(color: DebateTheme.textSecondary(context)),
                        filled: true,
                        fillColor: DebateTheme.surfaceElevated(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      loc.submitResult,
                      style: AppTextStyles.button(context).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          style: AppTextStyles.subtitle(context)
              .copyWith(fontWeight: FontWeight.w800, color: DebateTheme.textPrimary(context)),
        ),
      );
}

class _SideButton extends StatelessWidget {
  final String label;
  final DebateSide side;
  final bool selected;
  final VoidCallback onTap;
  const _SideButton({
    required this.label,
    required this.side,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = DebateTheme.sideColor(side);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : DebateTheme.surfaceElevated(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.button(context).copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? color : DebateTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageSlider extends StatelessWidget {
  final ResultStageRef stage;
  final int value;
  final ValueChanged<int> onChanged;
  const _StageSlider({required this.stage, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = stage.side != null ? DebateTheme.sideColor(stage.side!) : JadalColors.judgesGrey;
    // Integer 0–100 for every stage (incl. reply) — the backend stores an
    // integer; no 59–90 range, no reply-halving, no 0.5 steps.
    const min = 0.0;
    const max = 100.0;
    const divisions = 100;
    final shown = value.clamp(min.toInt(), max.toInt());
    final display = shown.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context)
                      .copyWith(fontWeight: FontWeight.w800, color: color),
                ),
                if (stage.speakerName.isNotEmpty)
                  Text(
                    stage.speakerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small(context)
                        .copyWith(color: DebateTheme.textSecondary(context)),
                  ),
              ],
            ),
          ),
          // A one-point nudge on each side of the slider — the full 0–100 drag
          // is too coarse to land on an exact score, so these do the fine steps.
          _StepButton(
            icon: Icons.remove_rounded,
            color: color,
            onTap: shown > min.toInt() ? () => onChanged(shown - 1) : null,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.16),
                // The value bubble (pointer) follows the side colour, not blue.
                valueIndicatorColor: color,
                valueIndicatorTextStyle: AppTextStyles.button(context)
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                showValueIndicator: ShowValueIndicator.onDrag,
              ),
              child: Slider(
                value: shown.toDouble(),
                min: min,
                max: max,
                divisions: divisions,
                label: display,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            color: color,
            onTap: shown < max.toInt() ? () => onChanged(shown + 1) : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              display,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyEmphasis(context)
                  .copyWith(fontWeight: FontWeight.w900, color: DebateTheme.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small circular −/+ button that steps a stage score by one point. Disabled
/// (dimmed, no tap) at the ends of the range.
class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      type: MaterialType.transparency,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: enabled ? 0.14 : 0.05),
            border: Border.all(color: color.withValues(alpha: enabled ? 0.5 : 0.18)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color.withValues(alpha: enabled ? 1 : 0.35),
          ),
        ),
      ),
    );
  }
}
