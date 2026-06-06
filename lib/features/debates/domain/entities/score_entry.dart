import 'package:equatable/equatable.dart';

class ScoreEntry extends Equatable {
  final String debaterId;
  final String debaterName;
  final int score;
  final String comment;

  const ScoreEntry({
    required this.debaterId,
    required this.debaterName,
    required this.score,
    required this.comment,
  });

  ScoreEntry copyWith({String? debaterId, String? debaterName, int? score, String? comment}) =>
      ScoreEntry(
        debaterId: debaterId ?? this.debaterId,
        debaterName: debaterName ?? this.debaterName,
        score: score ?? this.score,
        comment: comment ?? this.comment,
      );

  @override
  List<Object?> get props => [debaterId, debaterName, score, comment];
}
