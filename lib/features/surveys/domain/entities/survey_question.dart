/// A single question inside a survey.
/// `type` is one of: `rating`, `mcq`, `open_text`.
/// - `rating` → [options] is a `{min, max, step}` map.
/// - `mcq` → [options] is a `List<String>` of choices.
/// - `open_text` → [options] is `null`.
class SurveyQuestion {
  final int id;
  final String questionText;
  final String type;
  final dynamic options;
  final int orderIndex;

  const SurveyQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.options,
    required this.orderIndex,
  });

  bool get isRating => type == 'rating';
  bool get isMcq => type == 'mcq';
  bool get isOpenText => type == 'open_text';

  int get ratingMin => (options is Map) ? (options['min'] as num?)?.toInt() ?? 1 : 1;
  int get ratingMax => (options is Map) ? (options['max'] as num?)?.toInt() ?? 5 : 5;
  int get ratingStep => (options is Map) ? (options['step'] as num?)?.toInt() ?? 1 : 1;

  List<String> get mcqOptions => (options is List)
      ? (options as List).map((e) => e.toString()).toList()
      : const [];
}
