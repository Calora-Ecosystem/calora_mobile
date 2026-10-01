import 'package:intl/intl.dart';

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
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(localDateTime);
      return formattedDate;
    } catch (e) {
      return '${dateTime}';
    }
  }

  static String getBirthDate(String dateString) {
    final date = parseDateTime(dateString: dateString);
    return _formatDate(date);
  }

  /// `21 sentabr 2000` / `21 сентября 2000` / `21 September 2000`. Uses
  /// `Intl.defaultLocale`, which the app keeps in sync with the chosen
  /// language — a month list of nominatives would read "21 Сентябрь" in
  /// Russian.
  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMMM y').format(date);
  }

  static DateTime? parseIsoDateTime({required String dateString}) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}
