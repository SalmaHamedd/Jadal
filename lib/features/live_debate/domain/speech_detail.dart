import '../data/models/debate_models.dart';

/// How far along a speech's transcription is. The backend has no status field,
/// so this is inferred: an undelivered speech is not "missing a transcript", and
/// a delivered one with no text yet is still being prepared rather than empty.
enum TranscriptState { notDelivered, pending, ready }

/// One speech of the debate, as the judges' review screen needs it: who spoke,
/// how long they had, how long they took, how the POIs went, and the text.
class SpeechDetail {
  /// 1-based `order_index` — also the debate's speaking order.
  final int stageOrder;

  /// The stage's own name, e.g. "1st Proposition".
  final String label;

  final String speakerName;
  final String? speakerAvatarUrl;
  final String? speakerId;
  final DebateSide? side;
  final bool isReply;

  /// What the format allotted.
  final int? allottedSeconds;

  final DateTime? startedAt;
  final DateTime? endedAt;

  final int poisOffered;
  final int poisTaken;

  final String? speechText;

  const SpeechDetail({
    required this.stageOrder,
    required this.label,
    required this.speakerName,
    required this.speakerAvatarUrl,
    required this.speakerId,
    required this.side,
    required this.isReply,
    required this.allottedSeconds,
    required this.startedAt,
    required this.endedAt,
    required this.poisOffered,
    required this.poisTaken,
    required this.speechText,
  });

  bool get delivered => startedAt != null;

  /// Wall clock from start to end, so it includes any chair pause — the backend
  /// does not accumulate speaking time per phase. Null while still running.
  int? get takenSeconds {
    final from = startedAt;
    final to = endedAt;
    if (from == null || to == null) return null;
    final s = to.difference(from).inSeconds;
    return s < 0 ? null : s;
  }

  TranscriptState get transcriptState {
    if (!delivered) return TranscriptState.notDelivered;
    return (speechText?.trim().isNotEmpty ?? false)
        ? TranscriptState.ready
        : TranscriptState.pending;
  }
}
