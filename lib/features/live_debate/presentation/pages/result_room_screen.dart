import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/debate_room_shell.dart';
import '../widgets/debate_screen_header.dart';
import '../widgets/grid_layout.dart';
import '../widgets/result_submit_sheet.dart';
import '../widgets/result_summary_view.dart';
import 'speech_review_screen.dart';
import '../../../../core/error/failure_text.dart';

/// Result room. Locked until the chair finishes the debate; then:
/// the chair submits scores → reveals (confetti) or closes the main room; a
/// close with no result cancels the debate. Everyone else sees the shared
/// [ResultSummaryView] once revealed. Access is judge-only and gated in the lobby.
class ResultRoomScreen extends StatefulWidget {
  const ResultRoomScreen({super.key});

  @override
  State<ResultRoomScreen> createState() => _ResultRoomScreenState();
}

class _ResultRoomScreenState extends State<ResultRoomScreen> {
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    // Opened with an already-revealed result (e.g. the chair shared from the
    // live room) → celebrate on entry, but only the first time: this screen can
    // be re-opened from the menu afterwards.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<DebateController>();
      if (cubit.resultView?.revealed == true && !cubit.resultCelebrated) {
        cubit.markResultCelebrated();
        setState(() => _showConfetti = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      body: DebateRoomShell(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              DebateScreenHeader(title: loc.resultRoomTitle),
              Expanded(
                child: Stack(
                  children: [
                    BlocConsumer<DebateController, DebateStates>(
              listenWhen: (_, s) =>
                  s is ResultRevealedState || s is DebateErrorState,
              listener: (context, state) {
                if (state is ResultRevealedState) {
                  context.read<DebateController>().markResultCelebrated();
                  setState(() => _showConfetti = true);
                } else if (state is DebateErrorState) {
                  JadalSnackBar.show(context, FailureText.fromMessage(context, state.message), type: SnackBarType.error);
                }
              },
              buildWhen: (_, s) =>
                  s is DebateFinishedState ||
                  s is LiveStateUpdatedState ||
                  s is ResultRevealedState ||
                  s is DebateCancelledState ||
                  s is DebateConnectedState,
              builder: (context, _) => _body(context),
            ),
            if (_showConfetti)
              Positioned.fill(
                child: ConfettiOverlay(
                  onComplete: () {
                    if (mounted) setState(() => _showConfetti = false);
                  },
                ),
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final cubit = context.read<DebateController>();
    if (cubit.isCancelled) return const _Cancelled();
    // Gate on the result phase being open — the speeches can finish while the
    // debate is still `live`, so `debateFinished`/`completed` is too late.
    if (!cubit.resultPhaseOpen) return const _NotReady();

    final view = cubit.resultView;
    if (view == null) {
      // No ballot stored yet. The whole panel gets the judges' room; only the
      // chair gets the buttons that act on it. Anyone else waits.
      return cubit.isJudgeOfDebate
          ? _JudgesResultPanel(cubit: cubit)
          : const _ResultsPending();
    }

    // Read-only here — "share result" lives in the live room instead.
    return Column(
      children: [
        if (!view.revealed && cubit.isJudgeOfDebate)
          _AwaitingRevealNote(submittedAt: view.submittedAt),
        Expanded(child: ResultSummaryView(result: view)),
        if (cubit.isJudgeOfDebate) _ReviewSpeechesButton(cubit: cubit),
        // Rating posts as the signed-in user, so guests only read the result.
        if (view.revealed && !cubit.isGuest) _RatingBar(cubit: cubit),
      ],
    );
  }
}

/// The judges' room while no ballot is stored: who is here, the speech review,
/// and — for the chair alone — the actions that decide the debate.
class _JudgesResultPanel extends StatelessWidget {
  final DebateController cubit;
  const _JudgesResultPanel({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final canSubmit = cubit.canManageResult;
    // Only the judges ACTUALLY present in the result room (real LiveKit
    // presence), not the full judge roster (mock reports everyone present).
    final tiles = [
      for (final j in cubit.data.judges)
        if (cubit.isUserPresent(j.id)) GridParticipant(id: j.id, name: j.name),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(loc.noResultYet,
              style: AppTextStyles.title(context)
                  .copyWith(color: DebateTheme.textPrimary(context))),
        ),
        Expanded(child: GridLayout(participants: tiles)),
        _ReviewSpeechesButton(cubit: cubit),
        if (canSubmit) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                icon: const Icon(Icons.emoji_events_rounded),
                label: Text(loc.submitResult,
                    style: AppTextStyles.button(context).copyWith(fontWeight: FontWeight.w800)),
                onPressed: () async {
                  final ok = await ResultSubmitSheet.show(context, cubit);
                  if (ok == true && context.mounted) {
                    JadalSnackBar.show(context, loc.resultSubmittedMsg,
                        type: SnackBarType.success);
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton(
              onPressed: () => _confirmCloseNoResult(context, cubit),
              child: Text(loc.closeWithoutResult,
                  style: AppTextStyles.button(context).copyWith(color: const Color(0xFFE53935))),
            ),
          ),
        ],
      ],
    );
  }
}

/// Opens the per-speech review without leaving the room — the judge stays
/// connected the whole time, so this pushes a route rather than navigating away.
class _ReviewSpeechesButton extends StatelessWidget {
  final DebateController cubit;
  const _ReviewSpeechesButton({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.record_voice_over_rounded),
          label: Text(context.loc.reviewSpeeches,
              style: AppTextStyles.button(context).copyWith(fontWeight: FontWeight.w700)),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const SpeechReviewScreen(),
            ),
          )),
        ),
      ),
    );
  }
}

/// The ballot is in but not public yet — tells the panel that, instead of
/// leaving them on a screen that looks like nothing has happened.
class _AwaitingRevealNote extends StatelessWidget {
  final DateTime? submittedAt;
  const _AwaitingRevealNote({required this.submittedAt});

  @override
  Widget build(BuildContext context) {
    final at = submittedAt?.toLocal();
    final time = at == null
        ? ''
        : ' (${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')})';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DebateTheme.surfaceElevated(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JadalColors.primaryBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.how_to_vote_rounded, size: 20, color: JadalColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${context.loc.resultSubmittedAwaitingReveal}$time',
              style: AppTextStyles.caption(context)
                  .copyWith(color: DebateTheme.textSecondary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

void _confirmCloseNoResult(BuildContext context, DebateController cubit) {
  final loc = context.loc;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: DebateTheme.surface(context),
      title: Text(loc.debateCancelledTitle, style: AppTextStyles.title(context)),
      content: Text(loc.debateCancelledBody, style: AppTextStyles.body(context)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).maybePop();
            cubit.closeMain();
          },
          child: Text(loc.confirm, style: const TextStyle(color: Color(0xFFE53935))),
        ),
      ],
    ),
  );
}

/// A 1–5 star rating with an optional free-text explanation. The stars
/// stay editable — nothing is sent while picking. One request per explicit
/// Submit tap ([DebateController.sendDebateRating]); after a submit the rating
/// can still be changed and re-submitted ("update").
class _RatingBar extends StatefulWidget {
  final DebateController cubit;
  const _RatingBar({required this.cubit});

  @override
  State<_RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<_RatingBar> {
  final _commentController = TextEditingController();
  int _rating = 0;
  int _sentRating = 0;
  String _sentComment = '';
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _hasSent => _sentRating > 0;

  /// Submit enabled only when there's a rating and something actually changed
  /// since the last send — so re-tapping can't fire duplicate requests.
  bool get _canSubmit =>
      !_sending &&
      _rating > 0 &&
      (_rating != _sentRating || _commentController.text.trim() != _sentComment);

  Future<void> _submit() async {
    final rating = _rating;
    final comment = _commentController.text.trim();
    setState(() => _sending = true);
    await widget.cubit.sendDebateRating(rating, comment: comment);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sentRating = rating;
      _sentComment = comment;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: DebateTheme.surfaceElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JadalColors.primaryBlue.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            _hasSent ? loc.ratingThanks : loc.rateDebate,
            style: AppTextStyles.bodyEmphasis(context)
                .copyWith(color: DebateTheme.textPrimary(context)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      _sending ? null : () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF5C542),
                    size: 30,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _commentController,
            enabled: !_sending,
            maxLines: 2,
            minLines: 1,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.body(context)
                .copyWith(color: DebateTheme.textPrimary(context)),
            decoration: InputDecoration(
              hintText: loc.ratingCommentHint,
              hintStyle: AppTextStyles.caption(context)
                  .copyWith(color: DebateTheme.textSecondary(context)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: JadalColors.primaryBlue.withValues(alpha: 0.25),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: JadalColors.primaryBlue.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _hasSent ? loc.updateRating : loc.submitRating,
                style: AppTextStyles.button(context).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsPending extends StatelessWidget {
  const _ResultsPending();

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return _CenteredMessage(
      icon: Icons.hourglass_top_rounded,
      title: loc.resultsPending,
      body: loc.resultsNotReadyBody,
    );
  }
}

class _Cancelled extends StatelessWidget {
  const _Cancelled();

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return _CenteredMessage(
      icon: Icons.cancel_rounded,
      title: loc.debateCancelledTitle,
      body: loc.debateCancelledBody,
      iconColor: const Color(0xFFE53935),
    );
  }
}

class _NotReady extends StatelessWidget {
  const _NotReady();

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return _CenteredMessage(
      icon: Icons.lock_clock_rounded,
      title: loc.resultsNotReady,
      body: loc.resultsNotReadyBody,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color? iconColor;
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor ?? JadalColors.judgesGrey),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headline(context)
                    .copyWith(color: DebateTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context)
                    .copyWith(color: DebateTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }
}
