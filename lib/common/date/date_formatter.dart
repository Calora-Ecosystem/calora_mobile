import 'dart:developer';

import 'package:calora/common/gen/strings.dart';
import 'package:easy_localization/easy_localization.dart';

class DateFormatter {
  static Duration acceptedDifference = const Duration(minutes: 15);

  static int getCurrentTimeMillis() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  static String formatDateWithoutSecond(String date) {
    final DateFormat inputDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final DateTime dateTime = inputDateFormat.parse(date);

    final DateFormat outputDateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return outputDateFormat.format(dateTime);
  }

  static DateTime? parseDateTime({required String dateString}) {
    try {
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      return dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static String getDateTimeWithoutHours(DateTime? dateTime) {
    try {
      final DateTime localDateTime = dateTime == null
          ? DateTime.now().toLocal()
          : dateTime.toLocal();
      final String formattedDate = DateFormat('yyyy-MM-dd').format(localDateTime);
      return formattedDate;
    } catch (e) {
      return '${dateTime}';
    }
  }

  static String getBirthDate(String dateString) {
    final date = parseDateTime(dateString: dateString);
    return _formatDate(date);
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';

    final monthNames = [
      Strings.january,
      Strings.february,
      Strings.march,
      Strings.april,
      Strings.may,
      Strings.june,
      Strings.july,
      Strings.august,
      Strings.september,
      Strings.october,
      Strings.november,
      Strings.december,
    ];

    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  static DateTime? parseIsoDateTime({required String dateString}) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}
