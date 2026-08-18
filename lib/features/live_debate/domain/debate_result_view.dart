import '../data/models/debate_models.dart';
import '../data/models/live_state_model.dart';

/// 'proposition' | 'opposition' → [DebateSide] (null for anything else).
DebateSide? debateSideFromString(String? s) {
  switch (s) {
    case 'proposition':
      return DebateSide.proposition;
    case 'opposition':
      return DebateSide.opposition;
  }
  return null;
}

/// A scoreable stage descriptor for the chair's result-submit UI. One per
/// speech (6 or 8, reply speeches included). [stageOrder] is the 1-based order
/// that maps to `stage_scores.stage_order` in the submit payload.
class ResultStageRef {
  final int stageOrder;
  final String roleLabel; // P1 / O2 / PR … (test) or the backend stage name
  final String speakerName; // may be empty when the mapping is unavailable
  final DebateSide? side;
  final bool isReply;

  const ResultStageRef({
    required this.stageOrder,
    required this.roleLabel,
    required this.speakerName,
    required this.side,
    required this.isReply,
  });
}

/// One scored speech in the revealed result.
class ResultSpeechScore {
  final int stageOrder;
  final String roleLabel;
  final String speakerName;
  final DebateSide? side;
  final bool isReply;
  final num? score; // null until scored

  const ResultSpeechScore({
    required this.stageOrder,
    required this.roleLabel,
    required this.speakerName,
    required this.side,
    required this.isReply,
    required this.score,
  });
}

/// The shared, render-ready result the result widget shows in **both** the live
/// result room and the debate-list "Done" detail. Built locally by the
/// test cubit, or from a [LiveStateModel] (backend mode + list detail). Keeping
/// it cubit-free lets the same widget render it anywhere.
class DebateResultView {
  final DebateSide? winningSide;
  final String? winningTeamName;
  final String? losingTeamName;
  final String? summaryNotes;
  final List<ResultSpeechScore> speeches;

  /// Whether the chair has revealed the result. Drives the winner/crown reveal
  /// and the confetti — scores may be present before this is true.
  final bool revealed;

  /// When the chair stored it. Null in test mode and for older payloads.
  final DateTime? submittedAt;

  const DebateResultView({
    required this.winningSide,
    required this.winningTeamName,
    required this.losingTeamName,
    required this.summaryNotes,
    required this.speeches,
    required this.revealed,
    this.submittedAt,
  });

  bool get hasScores => speeches.any((s) => s.score != null);

  /// Best speaker = the highest-scoring **non-reply** speech. Returns null
  /// when there are no scores or no stage→speaker mapping, in which case the
  /// crown is simply hidden.
  ResultSpeechScore? get bestSpeaker {
    ResultSpeechScore? best;
    for (final s in speeches) {
      if (s.isReply || s.score == null || s.speakerName.isEmpty) continue;
      if (best == null || s.score! > best.score!) best = s;
    }
    return best;
  }

  /// Backend / list mapping. Stage→speaker via `participant_id`; degrades
  /// gracefully (empty name, no crown) when those fields are null.
  factory DebateResultView.fromLiveState(LiveStateModel state) {
    final result = state.result;
    final speeches = <ResultSpeechScore>[
      for (final stage in state.stages)
        () {
          final sp = state.speakerByParticipantId(stage.participantId);
          return ResultSpeechScore(
            stageOrder: stage.orderIndex,
            roleLabel: stage.name.isNotEmpty ? stage.name : '#${stage.orderIndex}',
            speakerName: sp?.user.name ?? '',
            side: debateSideFromString(sp?.side),
            isReply: stage.isReply,
            score: result?.scoreForStage(stage.orderIndex),
          );
        }(),
    ];
    final winning = debateSideFromString(result?.winningSide);
    String? nameFor(DebateSide? s) {
      if (s == DebateSide.proposition) return state.proposition.team?.name;
      if (s == DebateSide.opposition) return state.opposition.team?.name;
      return null;
    }

    return DebateResultView(
      winningSide: winning,
      winningTeamName: nameFor(winning),
      losingTeamName: nameFor(winning?.other),
      summaryNotes: result?.summaryNotes,
      speeches: speeches,
      revealed: state.debate.resultRevealed,
      submittedAt: result?.submittedAt,
    );
  }
}
