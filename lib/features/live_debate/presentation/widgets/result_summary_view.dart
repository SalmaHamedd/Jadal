import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/debate_result_view.dart';
import '../utils/debate_theme.dart';

const Color _gold = Color(0xFFF5C542);

/// The shared, render-ready result view (§10): winner appreciation, the
/// best-speaker crown, and the per-speech scores. Deliberately **cubit-free** —
/// it takes a [DebateResultView] so the live result room and the debate-list
/// "Done" detail (§13) render the exact same widget. Winner/crown/notes appear
/// only once [DebateResultView.revealed] is true; scores may show beforehand.
class ResultSummaryView extends StatelessWidget {
  final DebateResultView result;

  /// When true the inner list shrink-wraps and doesn't scroll — so it can nest
  /// inside another scroll view (the debate-list "Done" detail, §13).
  final bool shrinkWrap;

  const ResultSummaryView({super.key, required this.result, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final best = result.bestSpeaker;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if (result.revealed) _WinnerHero(result: result) else const _AwaitingReveal(),
        if (result.revealed && best != null) ...[
          const SizedBox(height: 14),
          _BestSpeakerCard(speaker: best),
        ],
        if (result.hasScores) ...[
          const SizedBox(height: 20),
          Text(
            loc.perSpeechScores,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: DebateTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          for (final s in result.speeches)
            _SpeechScoreRow(speech: s, isBest: result.revealed && identical(s, best)),
        ],
        if (result.revealed && (result.summaryNotes?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 18),
          _NotesBlock(notes: result.summaryNotes!.trim()),
        ],
      ],
    );
  }
}

class _WinnerHero extends StatelessWidget {
  final DebateResultView result;
  const _WinnerHero({required this.result});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final dark = DebateTheme.isDark(context);
    final side = result.winningSide;
    final gradient = side != null
        ? DebateTheme.sideGradient(side, dark)
        : [JadalColors.judgesGrey, JadalColors.judgesGrey.withValues(alpha: 0.7)];
    final team = result.winningTeamName ?? (side == null ? '—' : '');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: _gold, size: 52),
          const SizedBox(height: 8),
          Text(
            loc.winnerLabel.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            team,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.congratulations,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _AwaitingReveal extends StatelessWidget {
  const _AwaitingReveal();

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DebateTheme.surfaceElevated(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JadalColors.judgesGrey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: JadalColors.judgesGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.awaitingReveal,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: DebateTheme.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BestSpeakerCard extends StatelessWidget {
  final ResultSpeechScore speaker;
  const _BestSpeakerCard({required this.speaker});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final accent = speaker.side != null ? DebateTheme.sideColor(speaker.side!) : JadalColors.judgesGrey;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DebateTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: _gold.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: _gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.bestSpeakerLabel,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: _gold,
                  ),
                ),
                Text(
                  speaker.speakerName,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: DebateTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          _RolePill(label: speaker.roleLabel, color: accent),
          const SizedBox(width: 8),
          _ScoreText(score: speaker.score),
        ],
      ),
    );
  }
}

class _SpeechScoreRow extends StatelessWidget {
  final ResultSpeechScore speech;
  final bool isBest;
  const _SpeechScoreRow({required this.speech, required this.isBest});

  @override
  Widget build(BuildContext context) {
    final accent = speech.side != null ? DebateTheme.sideColor(speech.side!) : JadalColors.judgesGrey;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DebateTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          _RolePill(label: speech.roleLabel, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              speech.speakerName.isNotEmpty ? speech.speakerName : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: DebateTheme.textPrimary(context),
              ),
            ),
          ),
          if (isBest) const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.workspace_premium_rounded, color: _gold, size: 18),
          ),
          _ScoreText(score: speech.score),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final Color color;
  const _RolePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      constraints: const BoxConstraints(maxWidth: 110),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}

class _ScoreText extends StatelessWidget {
  final num? score;
  const _ScoreText({required this.score});

  @override
  Widget build(BuildContext context) {
    final value = score == null
        ? '—'
        : (score! % 1 == 0 ? score!.toInt().toString() : score!.toStringAsFixed(1));
    return Text(
      value,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w900,
        fontSize: 16,
        color: DebateTheme.textPrimary(context),
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  final String notes;
  const _NotesBlock({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DebateTheme.surfaceElevated(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JadalColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: JadalColors.primaryBlue, size: 20),
          const SizedBox(height: 6),
          Text(
            notes,
            style: TextStyle(
              fontFamily: 'Cairo',
              height: 1.4,
              color: DebateTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
