import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/containers/expandable_container.dart';
import 'package:calora/common/widgets/date_and_time/time_picker_widget.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class NotificationExpandableItem extends StatefulWidget {
  final String title;
  final String? initialTime;
  final bool initialEnabled;
  final bool isInterval;
  final Function(bool isEnabled, String time)? onChanged;
  const NotificationExpandableItem({
    super.key,
    required this.title,
    this.initialTime,
    this.initialEnabled = false,
    this.onChanged,
    this.isInterval = false,
  });

  @override
  State<NotificationExpandableItem> createState() => _NotificationExpandableItemState();
}

class _NotificationExpandableItemState extends State<NotificationExpandableItem> {
  String get currentTime => '${DateTime.now().hour.toString().padLeft(2, '0')}:00';

  late String selectedTime;
  bool isEnabled = false;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime ?? currentTime;
    isEnabled = widget.initialEnabled;
  }

  void _notifyParent() => widget.onChanged?.call(isEnabled, selectedTime);

  @override
  void didUpdateWidget(covariant NotificationExpandableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEnabled != oldWidget.initialEnabled) {
      setState(() => isEnabled = widget.initialEnabled);
    }
    if (widget.initialTime != oldWidget.initialTime) {
      setState(() => selectedTime = widget.initialTime ?? currentTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableContainer(
      title: widget.title,
      minTileHeight: 54,
      margin: EdgeInsets.zero,
      initiallyExpanded: widget.initialEnabled,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      backgroundColor: context.colors.backgroundElevation,
      collapsedBackgroundColor: context.colors.backgroundElevation,
      useSwitch: true,
      onExpansionChanged: (expanded) {
        if (expanded && !isEnabled) {
          setState(() => isEnabled = true);
          _notifyParent();
        } else if (!expanded && isEnabled) {
          setState(() {
            isEnabled = false;
            selectedTime = currentTime;
          });
          _notifyParent();
        }
      },
      children: [
        ExpandableContainer(
          margin: EdgeInsets.zero,
          title: widget.isInterval ? Strings.everyNHour(hour: getHourFromTime(selectedTime)) : selectedTime,
          children: [
            TimePickerWidget(
              isInterval: widget.isInterval,
              initialTime: selectedTime,
              onChanged: (time) {
                setState(() => selectedTime = time);
                if (isEnabled) _notifyParent();
              },
            ),
          ],
        ),
      ],
    );
  }

  String getHourFromTime(String time) {
    final String hourPart = time.split(':').first;
    if (hourPart == '00') return '24';
    if (hourPart.startsWith('0') && hourPart.length == 2) return hourPart.substring(1);
    return hourPart;
  }
}
