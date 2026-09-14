import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Inline birthday picker — the wheels live directly in the question card, so
/// there is no full-screen modal covering the "Next" button and no separate
/// "Done" step. The user just swipes the day / month / year wheels. Emits a
/// sensible default on mount so the user can proceed without being forced to
/// touch it.
class DatePickerWidget extends StatefulWidget {
  final ValueChanged<DateTime>? onDateChanged;

  const DatePickerWidget({super.key, this.onDateChanged});

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late final DateTime _initialDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to a plausible adult birthday (25y) and publish it immediately so
    // "Next" is enabled the moment the user lands on this step.
    _initialDate = DateTime(now.year - 25, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDateChanged?.call(_initialDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: context.colors.commonBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.colors.textStrong,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          dateOrder: DatePickerDateOrder.dmy,
          initialDateTime: _initialDate,
          minimumYear: 1900,
          maximumYear: DateTime.now().year - 5,
          onDateTimeChanged: (val) => widget.onDateChanged?.call(val),
        ),
      ),
    );
  }
}
