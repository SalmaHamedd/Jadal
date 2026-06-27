import '../../../../core/function/json_utils.dart';

/// One per-stage score entry, used in both the submit payload and the read
/// shape: `{ stage_order, score }`.
class StageScore {
  final int stageOrder;
  final num score;

  const StageScore({required this.stageOrder, required this.score});

  Map<String, dynamic> toJson() => {'stage_order': stageOrder, 'score': score};

  factory StageScore.fromJson(Map<String, dynamic> j) => StageScore(
        stageOrder: asInt(j['stage_order']) ?? 0,
        score: asNum(j['score']) ?? 0,
      );
}

/// The chair's result **submit** payload for `POST /debates/{id}/result`
/// (Postman): `{ winning_side, summary_notes, stage_scores:[{stage_order,score}] }`.
/// One `stage_scores` entry per stage (6 or 8, reply stages included).
class DebateResultModel {
  final String winningSide; // 'proposition' | 'opposition'
  final String summaryNotes;
  final List<StageScore> stageScores;

  const DebateResultModel({
    required this.winningSide,
    required this.summaryNotes,
    required this.stageScores,
  });

  Map<String, dynamic> toJson() => {
        'winning_side': winningSide,
        'summary_notes': summaryNotes,
        'stage_scores': stageScores.map((e) => e.toJson()).toList(),
      };
}

/// The **read** shape of `live-state.result` (null until revealed). Assumed to
/// mirror the submit shape (open Q4 — confirm against a real revealed result).
class LiveResult {
  final String? winningSide;
  final String? summaryNotes;
  final List<StageScore> stageScores;

  const LiveResult({
    this.winningSide,
    this.summaryNotes,
    this.stageScores = const [],
  });

  factory LiveResult.fromJson(Map<String, dynamic> j) {
    // G1: the READ shape nests the per-stage scores under `scores.stages`
    // (`{stage_order, participant_id, user_id, score}`) and the notes under
    // `scores.notes` — NOT a top-level `stage_scores` (that is the SUBMIT shape).
    // Reading the wrong key left scores empty → blank result screen + no
    // best-speaker crown. Fall back to the legacy key defensively.
    final scores = asMap(j['scores']);
    final stageList = scores?['stages'] ?? j['stage_scores'];
    return LiveResult(
      winningSide: asString(j['winning_side']),
      summaryNotes: asString(j['summary_notes']) ?? asString(scores?['notes']),
      stageScores: asMapList(stageList).map(StageScore.fromJson).toList(),
    );
  }

  /// Score for a given stage `order_index`, or null if not scored.
  num? scoreForStage(int orderIndex) {
    for (final s in stageScores) {
      if (s.stageOrder == orderIndex) return s.score;
    }
    return null;
  }
}
