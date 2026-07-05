import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/debate_room_shell.dart';
import '../widgets/debate_screen_header.dart';
import '../widgets/grid_layout.dart';
import '../widgets/result_submit_sheet.dart';
import '../widgets/result_summary_view.dart';

/// Result room (§8.1 / §10). Locked until the chair finishes the debate; then:
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
    // live room) → celebrate on entry (§U4b).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<DebateController>().resultView?.revealed == true) {
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
                  setState(() => _showConfetti = true);
                } else if (state is DebateErrorState) {
                  JadalSnackBar.show(context, state.message, type: SnackBarType.error);
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
    // FE-3: gate on the result phase being open (speeches done while the debate
    // is STILL `live`), never on `debateFinished`/`completed`.
    if (!cubit.resultPhaseOpen) return const _NotReady();

    final view = cubit.resultView;
    if (view == null) {
      // Result phase open, no result yet: the chair submits; everyone else waits.
      return cubit.canManageResult ? _ChairSubmitPrompt(cubit: cubit) : const _ResultsPending();
    }

    // FE-2/FE-6: the result room is submit-/read-only — "share result" moved to
    // the LIVE room, so there is no chair-controls/share bar here.
    return Column(
      children: [
        Expanded(child: ResultSummaryView(result: view)),
        if (view.revealed) _RatingBar(cubit: cubit),
      ],
    );
  }
}

/// Chair, debate finished, no result yet: judges grid + the submit entry point.
class _ChairSubmitPrompt extends StatelessWidget {
  final DebateController cubit;
  const _ChairSubmitPrompt({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    // Issue 1: only the judges ACTUALLY present in the result room (real LiveKit
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
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: DebateTheme.textPrimary(context))),
        ),
        Expanded(child: GridLayout(participants: tiles)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              icon: const Icon(Icons.emoji_events_rounded),
              label: Text(loc.submitResult,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
              onPressed: () async {
                final ok = await ResultSubmitSheet.show(context, cubit);
                if (ok == true && context.mounted) {
                  JadalSnackBar.show(context, loc.resultSubmittedMsg, type: SnackBarType.success);
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
                style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFFE53935))),
          ),
        ),
      ],
    );
  }
}

void _confirmCloseNoResult(BuildContext context, DebateController cubit) {
  final loc = context.loc;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: DebateTheme.surface(context),
      title: Text(loc.debateCancelledTitle, style: const TextStyle(fontFamily: 'Cairo')),
      content: Text(loc.debateCancelledBody, style: const TextStyle(fontFamily: 'Cairo')),
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

/// A 1–5 star rating with an optional free-text explanation (§10). The stars
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
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: DebateTheme.textPrimary(context),
            ),
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
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: DebateTheme.textPrimary(context),
            ),
            decoration: InputDecoration(
              hintText: loc.ratingCommentHint,
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
                color: DebateTheme.textSecondary(context),
              ),
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
                style: const TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.w800),
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
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: DebateTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', color: DebateTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }
}
