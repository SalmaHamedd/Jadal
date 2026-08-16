/// Compact, locale-neutral date label for debate cards/detail:
/// `yyyy-MM-dd HH:mm`, or an empty string when the date is absent.
String formatDebateDate(DateTime? d) {
  if (d == null) return '';
  final local = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
