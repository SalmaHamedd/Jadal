const _arabicWeekdays = <String>[
  'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
  'الجمعة', 'السبت', 'الأحد',
];

const _arabicMonths = <String>[
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

/// Returns "<weekday> <day> <month> • HH:mm" without relying on intl locale data.
String formatArabicDateTime(DateTime dt) {
  final dow = _arabicWeekdays[(dt.weekday - 1) % 7];
  final month = _arabicMonths[dt.month - 1];
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$dow ${dt.day} $month • $hh:$mm';
}

String formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String formatCountdown(int totalSeconds) {
  if (totalSeconds < 0) totalSeconds = 0;
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
