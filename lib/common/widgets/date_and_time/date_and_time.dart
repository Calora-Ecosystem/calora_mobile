import 'package:intl/intl.dart';

/// Period label for the steps cards, e.g. `22 сентября` or
/// `15 sentabr - 21 sentabr`. [locale] is the app language code
/// (`context.locale.languageCode`) so the month follows the chosen language
/// instead of a hardcoded one.
String formatDateLabel(int offset, String period, String locale) {
  final now = DateTime.now();
  final day = DateFormat('d MMMM', locale);
  final paddedDay = DateFormat('dd MMMM', locale);

  if (period == 'daily') {
    final today = DateTime(now.year, now.month, now.day);
    final target = today.add(Duration(days: offset));
    return day.format(target);
  } else if (period == 'weekly') {
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final targetStart = startOfWeek.add(Duration(days: offset * 7));
    final targetEnd = targetStart.add(const Duration(days: 6));

    return '${paddedDay.format(targetStart)} - ${paddedDay.format(targetEnd)}';
  } else if (period == 'monthly') {
    final target = DateTime(now.year, now.month + offset);
    final firstDay = DateTime(target.year, target.month);
    final lastDay = DateTime(target.year, target.month + 1, 0);

    return '${paddedDay.format(firstDay)} - ${paddedDay.format(lastDay)}';
  }

  return '';
}
