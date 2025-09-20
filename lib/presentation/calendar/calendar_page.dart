import 'package:calora/common/date/date_formatter.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  final String? selectedDate;
  final Function(String) onSaveBirthDate;

  CalendarPage({
    super.key,
    required this.selectedDate,
    required this.onSaveBirthDate,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(50),
          height: 250,
          decoration: BoxDecoration(
            color: context.colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            dateOrder: DatePickerDateOrder.dmy,
            initialDateTime:
                _selectedDate ??
                DateTime(
                  DateTime.now().year - 5,
                  DateTime.now().month,
                  DateTime.now().day,
                ),
            onDateTimeChanged: (val) {
              setState(() {
                _selectedDate = val;
              });
            },
            minimumYear: 1900,
            maximumYear: DateTime.now().year - 5,
          ),
        ),
        const SizedBox(height: 50),
        GestureDetector(
          onTap: () {
            widget.onSaveBirthDate(DateFormatter.getDateTimeWithoutHours(_selectedDate));
          },
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.accentSub,
              borderRadius: BorderRadius.circular(12),
            ),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Strings.save
                .text(16, 20, 500)
                .c(context.colors.white)
                .copyWith(textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
