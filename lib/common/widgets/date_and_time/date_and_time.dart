String formatDateLabel(int offset, String period) {
  final now = DateTime.now();

  String monthName(int month) {
    const months = [
      "Yanvar",
      "Fevral",
      "Mart",
      "Aprel",
      "May",
      "Iyun",
      "Iyul",
      "Avgust",
      "Sentyabr",
      "Oktabr",
      "Noyabr",
      "Dekabr",
    ];
    return months[month - 1];
  }

  if (period == "daily") {
    final today = DateTime(now.year, now.month, now.day);
    final target = today.add(Duration(days: offset));
    return "${target.day} ${monthName(target.month)}";
  } else if (period == "weekly") {
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final targetStart = startOfWeek.add(Duration(days: offset * 7));
    final targetEnd = targetStart.add(const Duration(days: 6));

    return "${targetStart.day.toString().padLeft(2, '0')} ${monthName(targetStart.month)}"
        " - ${targetEnd.day.toString().padLeft(2, '0')} ${monthName(targetEnd.month)}";
  } else if (period == "monthly") {
    final target = DateTime(now.year, now.month + offset, 1);
    final firstDay = DateTime(target.year, target.month, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0);

    return "${firstDay.day.toString().padLeft(2, '0')} ${monthName(firstDay.month)}"
        " - ${lastDay.day.toString().padLeft(2, '0')} ${monthName(lastDay.month)}";
  }

  return "";
}
