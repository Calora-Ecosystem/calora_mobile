import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';

class TimePickerWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final double height;
  final String? initialTime;
  final bool isInterval;

  const TimePickerWidget({
    super.key,
    required this.onChanged,
    this.height = 138,
    this.initialTime,
    this.isInterval = false,
  });

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late FixedExtentScrollController _controller;
  late int _selectedIndex;

  late final List<String> _times;
  late final List<String> _displayValues;

  @override
  void initState() {
    super.initState();

    if (widget.isInterval) {
      _times = List.generate(24, (i) => '${(i + 1).toString().padLeft(2, '0')}:00');
      _displayValues = List.generate(_times.length, (i) => Strings.everyNHour(hour: i + 1));
    } else {
      _times = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
      _displayValues = List.from(_times);
    }

    _selectedIndex = _resolveInitialIndex();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged(_times[_selectedIndex]));
  }

  int _resolveInitialIndex() {
    if (widget.initialTime == null) {
      if (widget.isInterval) {
        final currentHour = DateTime.now().hour;
        if (currentHour == 0) return 23;
        return (currentHour - 1).clamp(0, 23);
      }
      return DateTime.now().hour;
    }
    String cleaned = widget.initialTime!;
    if (cleaned.length > 5) {
      cleaned = cleaned.substring(0, 5);
    }

    if (widget.isInterval && cleaned == '00:00') {
      cleaned = '24:00';
    }

    final index = _times.indexOf(cleaned);
    return index != -1 ? index : 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: CupertinoPicker(
        scrollController: _controller,
        itemExtent: widget.isInterval ? 30 : 45,
        diameterRatio: 2,
        useMagnifier: true,
        magnification: 1.1,
        squeeze: widget.isInterval ? 0.7 : 0.9,
        selectionOverlay: const SizedBox.shrink(),
        onSelectedItemChanged: (index) {
          setState(() => _selectedIndex = index);
          String timeToReturn = _times[index];
          if (widget.isInterval && timeToReturn == '24:00') {
            timeToReturn = '00:00';
          }
          widget.onChanged(timeToReturn);
        },
        children: _displayValues
            .map(
              (value) => widget.isInterval
                  ? Center(child: value.text(24, 30, 400).c(context.colors.defaultText))
                  : Center(child: value.text(35, 44, 400).c(context.colors.defaultText)),
            )
            .toList(),
      ),
    );
  }
}
