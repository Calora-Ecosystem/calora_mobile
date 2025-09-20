import 'package:calora/common/date/date_formatter.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class SelectCalendarPage extends StatefulWidget {
  final String title;
  final String? selectedDate;
  final Function(String) onSave;

  SelectCalendarPage({
    super.key,
    this.title = "",
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<SelectCalendarPage> createState() => _SelectCalendarPageState();
}

class _SelectCalendarPageState extends State<SelectCalendarPage> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Initialize selectedDate from widget parameter
    if (widget.selectedDate != null && widget.selectedDate!.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.selectedDate!);
      } catch (e) {
        _selectedDate = DateTime(
          DateTime.now().year - 5,
          DateTime.now().month,
          DateTime.now().day,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 2,
              width: 24,
              color: context.colors.strokeSub,
            ),
          ),
          const SizedBox(height: 8),
          widget.title.text(20, 24, 700).c(context.colors.textStrong),
          const SizedBox(height: 12),

          // Solution 2: Use SizedBox with fixed height for DatePicker
          SizedBox(
            height: 200, // Fixed height to prevent overflow
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

          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (_selectedDate != null) {
                final formattedDate = DateFormatter.getDateTimeWithoutHours(_selectedDate);
                widget.onSave(formattedDate);
              }
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}