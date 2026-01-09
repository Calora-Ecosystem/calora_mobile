import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarSelectorWidget extends StatefulWidget {
  final ValueChanged<DateTime> onDaySelected;
  final DateTime initialDate;

  const CalendarSelectorWidget({
    super.key,
    required this.onDaySelected,
    required this.initialDate,
  });

  @override
  _CalendarSelectorWidgetState createState() => _CalendarSelectorWidgetState();
}

class _CalendarSelectorWidgetState extends State<CalendarSelectorWidget> {
  late ScrollController _scrollController;
  DateTime? _selectedDate;
  final List<DateTime> _months = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeMonths();
    _selectedDate = widget.initialDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentMonth();
    });
  }

  void _scrollToCurrentMonth() {
    if (_selectedDate == null) return;

    final selected = _selectedDate!;
    final index = _months.indexWhere(
      (m) => m.year == selected.year && m.month == selected.month,
    );

    if (index != -1) {
      final targetIndex = (index - 1).clamp(0, _months.length - 1);

      _scrollController.animateTo(
        targetIndex * 330,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _initializeMonths() {
    final DateTime now = DateTime.now();

    for (int i = 6; i >= 1; i--) {
      _months.add(DateTime(now.year, now.month - i));
    }
    for (int i = 0; i <= 12; i++) {
      _months.add(DateTime(now.year, now.month + i));
    }
  }

  void _onDayTap(DateTime day) {
    final today = DateTime.now();
    if (day.isAfter(today)) return;

    setState(() {
      _selectedDate = day;
    });
  }

  void _onContinuePressed() {
    if (_selectedDate != null) {
      widget.onDaySelected(_selectedDate!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Strings.chooseDay
                  .text(20, 24, 600)
                  .c(context.colors.textStrong),
            ),
            const SizedBox(height: 8),
            _buildWeekdayHeaders(),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _months.length,
                itemBuilder: (context, index) {
                  return _buildMonthView(_months[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Button(
                onPressed: _onContinuePressed,
                text: Strings.continueBtn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    final locale = Localizations.localeOf(context).languageCode;
    final monday = DateTime(2023, 1, 2);
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map(
              (day) => DateFormat.E(locale)
                  .format(day)
                  .capitalize()
                  .text(16, 20, 400)
                  .c(context.colors.textStrong),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMonthView(DateTime month) {
    final List<DateTime> daysInMonth = _getDaysInMonth(month);
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: DateFormat.yMMMM('Uz')
              .format(month)
              .capitalize()
              .text(20, 24, 600)
              .c(context.colors.textStrong),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: daysInMonth.length,
          itemBuilder: (context, index) {
            final DateTime day = daysInMonth[index];
            final bool isCurrentMonth = day.month == month.month;
            final bool isAfterToday = day.isAfter(
              DateTime(today.year, today.month, today.day),
            );
            final bool isSelected =
                _selectedDate != null &&
                day.year == _selectedDate!.year &&
                day.month == _selectedDate!.month &&
                day.day == _selectedDate!.day;
            final bool isToday =
                day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;

            final canSelect = isCurrentMonth && !isAfterToday;

            return GestureDetector(
              onTap: canSelect ? () => _onDayTap(day) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.backgroundElevation
                      : isToday
                      ? context.colors.backgroundElevation6
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: day.day
                    .toString()
                    .text(16, 20, 400)
                    .c(
                      !isCurrentMonth || isAfterToday
                          ? context.colors.lightGray
                          : (isSelected
                                ? context.colors.textStrong
                                : context.colors.textStrong),
                    ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final List<DateTime> days = [];
    final int year = month.year;
    final int monthNum = month.month;

    final DateTime firstDayOfMonth = DateTime(year, monthNum);
    final int firstWeekday = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday;

    for (int i = 0; i < firstWeekday - 1; i++) {
      days.add(firstDayOfMonth.subtract(Duration(days: firstWeekday - i - 1)));
    }

    final DateTime lastDayOfMonth = DateTime(year, monthNum + 1, 0);
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(year, monthNum, i));
    }

    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }

    return days;
  }
}
