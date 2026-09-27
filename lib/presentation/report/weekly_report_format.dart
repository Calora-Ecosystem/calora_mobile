import 'package:calora/domain/model/report/weekly_report.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// `14 370` — thousands separated by a thin space, no decimals.
String formatInt(num value) =>
    NumberFormat('#,##0', 'en').format(value.round()).replaceAll(',', ' ');

/// `72.5` / `72` — kilograms with at most one decimal.
String formatKg(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? '${rounded.round()}'
      : rounded.toStringAsFixed(1);
}

/// `15 – 21 Sep` in the app language.
String weekRange(BuildContext context, WeeklyReport report) {
  final lang = context.locale.languageCode;
  try {
    final start = DateFormat.d(lang).format(report.weekStart);
    final end = DateFormat.MMMd(lang).format(report.weekEnd);
    return '$start – $end';
  } catch (_) {
    return '${report.weekStart.day}.${report.weekStart.month} – '
        '${report.weekEnd.day}.${report.weekEnd.month}';
  }
}

/// Monday of the previous (last complete) week.
DateTime lastWeekStart() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: today.weekday - 1 + 7));
}

/// Full weekday name, e.g. "Saturday" (Monday = 1).
String weekdayName(DateTime date) => 'wr_day_full_${date.weekday}'.tr();

/// `+12%` / `−8%`.
String formatPercent(double value) {
  final rounded = value.round();
  return rounded > 0
      ? '+$rounded%'
      : rounded < 0
      ? '−${-rounded}%'
      : '0%';
}

String badgeEmoji(String badge) => switch (badge) {
  'perfect_week' => '🏆',
  'consistent' => '📅',
  'step_master' => '👟',
  'step_goal' => '🎯',
  'protein_pro' => '💪',
  'hydrated' => '💧',
  _ => '⭐',
};
