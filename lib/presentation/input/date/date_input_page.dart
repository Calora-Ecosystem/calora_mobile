import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/switch/custom_switch.dart';
import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationSettingSheet extends StatefulWidget {
  final NotificationSettingType type;
  final Function(dynamic) onSave;

  const NotificationSettingSheet({super.key, required this.type, required this.onSave});

  @override
  State<NotificationSettingSheet> createState() => _NotificationSettingSheetState();
}

class _NotificationSettingSheetState extends State<NotificationSettingSheet> {
  bool isEnabled = false;
  int selectedIndex = 0;
  DateTime selectedTime = DateTime.now();

  bool breakfastEnabled = false, lunchEnabled = false, dinnerEnabled = false;
  int breakfastIndex = 0, lunchIndex = 0, dinnerIndex = 0;

  int? expandedMealIndex;
  final waterOptions = [
    Strings.every1Hour,
    Strings.every2Hour,
    Strings.every3Hour,
    Strings.every4Hour,
    Strings.every5Hour,
  ];
  final mealOptions = [
    Strings.before10Min,
    Strings.before20Min,
    Strings.before30Min,
    Strings.before40Min,
    Strings.before50Min,
  ];
  bool get _isTimePicker =>
      widget.type == NotificationSettingType.sleepReminder ||
      widget.type == NotificationSettingType.thirtyDayChallenges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Strings.settingUpReminders.text(20, 24, 700),
            const SizedBox(height: 16),
            if (widget.type == NotificationSettingType.waterReminder)
              _buildSettingBlock(
                title: Strings.waterDrinkReminder,
                isEnabled: isEnabled,
                onToggle: (v) => setState(() => isEnabled = v),
                options: waterOptions,
                selectedIndex: selectedIndex,
                onOptionChanged: (i) => setState(() => selectedIndex = i),
                isExpanded: isEnabled,
                onExpandToggle: () {},
              ),
            if (widget.type == NotificationSettingType.mealReminder) ...[
              _buildSettingBlock(
                title: Strings.breakfastTimeReminder,
                isEnabled: breakfastEnabled,
                onToggle: (v) => setState(() => breakfastEnabled = v),
                options: mealOptions,
                selectedIndex: breakfastIndex,
                onOptionChanged: (i) => setState(() => breakfastIndex = i),
                isExpanded: expandedMealIndex == 0 && breakfastEnabled,
                onExpandToggle: () => setState(() {
                  expandedMealIndex = expandedMealIndex == 0 ? null : 0;
                }),
              ),
              const SizedBox(height: 12),
              _buildSettingBlock(
                title: Strings.lunchTimeReminder,
                isEnabled: lunchEnabled,
                onToggle: (v) => setState(() => lunchEnabled = v),
                options: mealOptions,
                selectedIndex: lunchIndex,
                onOptionChanged: (i) => setState(() => lunchIndex = i),
                isExpanded: expandedMealIndex == 1 && lunchEnabled,
                onExpandToggle: () => setState(() {
                  expandedMealIndex = expandedMealIndex == 1 ? null : 1;
                }),
              ),
              const SizedBox(height: 12),
              _buildSettingBlock(
                title: Strings.dinnerTimeReminder,
                isEnabled: dinnerEnabled,
                onToggle: (v) => setState(() => dinnerEnabled = v),
                options: mealOptions,
                selectedIndex: dinnerIndex,
                onOptionChanged: (i) => setState(() => dinnerIndex = i),
                isExpanded: expandedMealIndex == 2 && dinnerEnabled,
                onExpandToggle: () => setState(() {
                  expandedMealIndex = expandedMealIndex == 2 ? null : 2;
                }),
              ),
            ],
            if (_isTimePicker)
              _buildSettingBlock(
                title: widget.type == NotificationSettingType.sleepReminder
                    ? Strings.bedtimeReminder
                    : Strings.reminderOfDailyChallangeTimes,
                isEnabled: isEnabled,
                onToggle: (v) => setState(() => isEnabled = v),
                selectedTime: selectedTime,
                onTimeChanged: (t) => setState(() => selectedTime = t),
                isExpanded: isEnabled,
                onExpandToggle: () {},
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                if (widget.type == NotificationSettingType.waterReminder && isEnabled) {
                  widget.onSave(waterOptions[selectedIndex]);
                } else if (widget.type == NotificationSettingType.mealReminder) {
                  final result = {};
                  if (breakfastEnabled) result["breakfast"] = mealOptions[breakfastIndex];
                  if (lunchEnabled) result["lunch"] = mealOptions[lunchIndex];
                  if (dinnerEnabled) result["dinner"] = mealOptions[dinnerIndex];
                  widget.onSave(result);
                } else if (_isTimePicker && isEnabled) {
                  widget.onSave(selectedTime);
                }
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.accentSub,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Strings.save
                    .text(16, 20, 500)
                    .c(context.colors.white)
                    .copyWith(textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingBlock({
    required String title,
    required bool isEnabled,
    required Function(bool) onToggle,
    required bool isExpanded,
    required VoidCallback onExpandToggle,
    List<String>? options,
    int? selectedIndex,
    Function(int)? onOptionChanged,
    DateTime? selectedTime,
    Function(DateTime)? onTimeChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              title.text(16, 20, 400).c(context.colors.textStrong),
              CustomSwitch(result: onToggle, value: isEnabled),
            ],
          ),
          if (isEnabled)
            Column(
              children: [
                SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: onExpandToggle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            (options != null && selectedIndex != null ? options[selectedIndex] : '')
                                .text(16, 20, 400)
                                .c(context.colors.textStrong),
                            isExpanded ? Assets.icons.down.svg() : Assets.icons.arrowDown.svg(),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 8),
                        if (options != null && selectedIndex != null && onOptionChanged != null)
                          SizedBox(
                            height: 120,
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(
                                initialItem: selectedIndex,
                              ),
                              itemExtent: 30,
                              selectionOverlay: null,
                              onSelectedItemChanged: onOptionChanged,
                              children: options.map((e) => e.text(24, 30, 400)).toList(),
                            ),
                          )
                        else if (selectedTime != null && onTimeChanged != null)
                          SizedBox(
                            height: 120,
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              initialDateTime: selectedTime,
                              selectionOverlayBuilder:
                                  (_, {required columnCount, required selectedIndex}) => null,
                              use24hFormat: true,
                              onDateTimeChanged: onTimeChanged,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
