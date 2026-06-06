import 'package:equatable/equatable.dart';

import 'debater.dart';
import 'score_entry.dart';

class DebateResults extends Equatable {
  final String debateId;
  final TeamSide winningSide;
  final int governmentTotal;
  final int oppositionTotal;
  final List<ScoreEntry> governmentScores;
  final List<ScoreEntry> oppositionScores;

  const DebateResults({
    required this.debateId,
    required this.winningSide,
    required this.governmentTotal,
    required this.oppositionTotal,
    required this.governmentScores,
    required this.oppositionScores,
  });

  @override
  List<Object?> get props => [
        debateId,
        winningSide,
        governmentTotal,
        oppositionTotal,
        governmentScores,
        oppositionScores,
      ];
}
