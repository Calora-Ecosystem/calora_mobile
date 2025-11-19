import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekDaysSelector extends StatefulWidget {
  final ValueChanged<DateTime> onDaySelected;

  const WeekDaysSelector({super.key, required this.onDaySelected});

  @override
  State<WeekDaysSelector> createState() => _WeekDaysSelectorState();
}

class _WeekDaysSelectorState extends State<WeekDaysSelector> {
  int selectedIndex = DateTime.now().weekday - 1;

  List<DateTime> getWeekDays() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  bool isFutureDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDay = DateTime(day.year, day.month, day.day);
    return checkDay.isAfter(today);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDaySelected(getWeekDays()[selectedIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = getWeekDays();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final dayName = DateFormat('EEE').format(day);
          final dayNumber = DateFormat('d').format(day);
          final isSelected = index == selectedIndex;
          final isDisabled = isFutureDay(day);

          return GestureDetector(
            onTap: () {
              if (isDisabled) return;
              setState(() => selectedIndex = index);
              widget.onDaySelected(day);
            },
            child: Container(
              width: 48,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? context.colors.accentSub : context.colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  dayName
                      .text(12, 14, 500)
                      .c(
                        isDisabled
                            ? context.colors.lightGray
                            : isSelected
                            ? context.colors.white
                            : context.colors.textSub,
                      ),
                  const SizedBox(height: 2),
                  dayNumber
                      .text(14, 16, 600)
                      .c(
                        isDisabled
                            ? context.colors.lightGray
                            : isSelected
                            ? context.colors.white
                            : context.colors.textStrong,
                      ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
      ),
    );
  }
}
