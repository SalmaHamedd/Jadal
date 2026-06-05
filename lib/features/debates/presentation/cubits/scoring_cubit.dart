import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/debate_results.dart';
import '../../domain/entities/score_entry.dart';
import '../../domain/repositories/debate_repositories.dart';

enum ScoringUploadStatus { idle, uploading, success, error }

class ScoringState extends Equatable {
  final bool isLoading;
  final List<ScoreEntry> governmentScores;
  final List<ScoreEntry> oppositionScores;
  final ScoringUploadStatus uploadStatus;
  final DebateResults? uploaded;
  final String? error;

  const ScoringState({
    this.isLoading = true,
    this.governmentScores = const [],
    this.oppositionScores = const [],
    this.uploadStatus = ScoringUploadStatus.idle,
    this.uploaded,
    this.error,
  });

  int get governmentTotal => governmentScores.fold(0, (s, e) => s + e.score);
  int get oppositionTotal => oppositionScores.fold(0, (s, e) => s + e.score);

  ScoringState copyWith({
    bool? isLoading,
    List<ScoreEntry>? governmentScores,
    List<ScoreEntry>? oppositionScores,
    ScoringUploadStatus? uploadStatus,
    DebateResults? uploaded,
    String? error,
    bool clearError = false,
  }) =>
      ScoringState(
        isLoading: isLoading ?? this.isLoading,
        governmentScores: governmentScores ?? this.governmentScores,
        oppositionScores: oppositionScores ?? this.oppositionScores,
        uploadStatus: uploadStatus ?? this.uploadStatus,
        uploaded: uploaded ?? this.uploaded,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        isLoading,
        governmentScores,
        oppositionScores,
        uploadStatus,
        uploaded,
        error,
      ];
}

class ScoringCubit extends Cubit<ScoringState> {
  final ScoringRepository _repo;
  final String _debateId;
  final List<String> _governmentIds;

  ScoringCubit({
    required ScoringRepository repo,
    required String debateId,
    required List<String> governmentDebaterIds,
  })  : _repo = repo,
        _debateId = debateId,
        _governmentIds = governmentDebaterIds,
        super(const ScoringState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final drafts = await _repo.draftScoresFor(_debateId);
    final gov = drafts.where((d) => _governmentIds.contains(d.debaterId)).toList();
    final opp = drafts.where((d) => !_governmentIds.contains(d.debaterId)).toList();
    emit(state.copyWith(
      isLoading: false,
      governmentScores: gov,
      oppositionScores: opp,
    ));
  }

  void updateScore(String debaterId, int newScore) {
    emit(state.copyWith(
      governmentScores: _updateOne(state.governmentScores, debaterId, score: newScore),
      oppositionScores: _updateOne(state.oppositionScores, debaterId, score: newScore),
    ));
  }

  void updateComment(String debaterId, String newComment) {
    emit(state.copyWith(
      governmentScores:
          _updateOne(state.governmentScores, debaterId, comment: newComment),
      oppositionScores:
          _updateOne(state.oppositionScores, debaterId, comment: newComment),
    ));
  }

  Future<void> upload() async {
    emit(state.copyWith(uploadStatus: ScoringUploadStatus.uploading, clearError: true));
    try {
      final results = await _repo.uploadFinalResults(
        debateId: _debateId,
        governmentScores: state.governmentScores,
        oppositionScores: state.oppositionScores,
      );
      emit(state.copyWith(
        uploadStatus: ScoringUploadStatus.success,
        uploaded: results,
      ));
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: ScoringUploadStatus.error,
        error: e.toString(),
      ));
    }
  }

  List<ScoreEntry> _updateOne(
    List<ScoreEntry> list,
    String debaterId, {
    int? score,
    String? comment,
  }) {
    return list
        .map((e) =>
            e.debaterId == debaterId ? e.copyWith(score: score, comment: comment) : e)
        .toList();
  }
}
