import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DatePickerScreen extends StatefulWidget {
  final ValueChanged<DateTime>? onDateChanged;

  const DatePickerScreen({super.key, this.onDateChanged});

  @override
  _DatePickerScreenState createState() => _DatePickerScreenState();
}

class _DatePickerScreenState extends State<DatePickerScreen> {
  DateTime? _selectedDate;

  void _showDatePicker(BuildContext ctx) {
    showCupertinoModalPopup(
      context: ctx,
      barrierColor: Colors.transparent,
      builder: (_) => Container(
        height: 350,
        color: context.colors.modalBackground,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(50),
              height: 250,
              decoration: BoxDecoration(
                color: context.colors.accentWhite,
                borderRadius: BorderRadius.circular(13),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                dateOrder: DatePickerDateOrder.dmy,
                initialDateTime:
                    _selectedDate ??
                    DateTime(DateTime.now().year - 5, DateTime.now().month, DateTime.now().day),
                onDateTimeChanged: (val) {
                  setState(() {
                    _selectedDate = val;
                  });
                  if (widget.onDateChanged != null) {
                    widget.onDateChanged!(val);
                  }
                },
                minimumYear: 1900,
                maximumYear: DateTime.now().year - 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showDatePicker(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDatePart("Kun", _selectedDate?.day.toString()),
              const SizedBox(width: 8),
              _buildDatePart("Oy", _selectedDate?.month.toString()),
              const SizedBox(width: 8),
              _buildDatePart("Yil", _selectedDate?.year.toString()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePart(String label, String? value) {
    final displayValue = (value == null || value.isEmpty) ? label : value.padLeft(2, '0');
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: context.colors.commonBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: displayValue
            .text(14, 18, 500)
            .c(context.colors.textStrong)
            .copyWith(textAlign: TextAlign.center),
      ),
    );
  }
}
