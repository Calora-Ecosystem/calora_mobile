// notification_setting_sheet.dart
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/switch/custom_switch.dart';
import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/input/date/management/notification_setting_sheet_management.dart';
import 'package:calora/presentation/input/date/management/notification_setting_sheet_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class NotificationSettingSheet
    extends
        Managed<
          NotificationSettingSheetManager,
          NotificationSettingSheetState,
          NotificationSettingSheetEffect
        > {
  final NotificationSettingType type;
  final List<ReminderRequest> reminders;

  NotificationSettingSheet({super.key, required this.type, required this.reminders});

  @override
  void init(BuildContext context, NotificationSettingSheetManager manager) {
    manager.init(type, reminders);
  }

  @override
  void listener(
    BuildContext context,
    NotificationSettingSheetManager manager,
    NotificationSettingSheetEffect effect,
  ) {
    effect.when(
      save: (type, data) => Navigator.pop(context),
      delete: (id) => null, // Delete backend orqali boshqariladi
    );
  }

  @override
  Widget builder(
    BuildContext context,
    NotificationSettingSheetManager manager,
    NotificationSettingSheetState state,
  ) {
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
    final bool isTimePicker =
        type == NotificationSettingType.sleepReminder ||
        type == NotificationSettingType.thirtyDayChallenges;

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
            if (type == NotificationSettingType.waterReminder)
              _buildSettingBlock(
                context: context,
                manager: manager,
                state: state,
                title: Strings.waterDrinkReminder,
                isEnabled: state.isEnabled,
                onToggle: manager.toggleEnabled,
                options: waterOptions,
                selectedIndex: state.selectedIndex,
                onOptionChanged: manager.setSelectedIndex,
                isExpanded: state.isEnabled,
                onExpandToggle: () {},
              ),
            if (type == NotificationSettingType.mealReminder) ...[
              _buildSettingBlock(
                context: context,
                manager: manager,
                state: state,
                title: Strings.breakfastTimeReminder,
                isEnabled: state.breakfastEnabled,
                onToggle: manager.toggleBreakfastEnabled,
                options: mealOptions,
                selectedIndex: state.breakfastIndex,
                onOptionChanged: manager.setBreakfastIndex,
                isExpanded: state.expandedMealIndex == 0 && state.breakfastEnabled,
                onExpandToggle: () => manager.toggleExpandedMealIndex(0),
              ),
              const SizedBox(height: 12),
              _buildSettingBlock(
                context: context,
                manager: manager,
                state: state,
                title: Strings.lunchTimeReminder,
                isEnabled: state.lunchEnabled,
                onToggle: manager.toggleLunchEnabled,
                options: mealOptions,
                selectedIndex: state.lunchIndex,
                onOptionChanged: manager.setLunchIndex,
                isExpanded: state.expandedMealIndex == 1 && state.lunchEnabled,
                onExpandToggle: () => manager.toggleExpandedMealIndex(1),
              ),
              const SizedBox(height: 12),
              _buildSettingBlock(
                context: context,
                manager: manager,
                state: state,
                title: Strings.dinnerTimeReminder,
                isEnabled: state.dinnerEnabled,
                onToggle: manager.toggleDinnerEnabled,
                options: mealOptions,
                selectedIndex: state.dinnerIndex,
                onOptionChanged: manager.setDinnerIndex,
                isExpanded: state.expandedMealIndex == 2 && state.dinnerEnabled,
                onExpandToggle: () => manager.toggleExpandedMealIndex(2),
              ),
            ],
            if (isTimePicker)
              _buildSettingBlock(
                context: context,
                manager: manager,
                state: state,
                title: type == NotificationSettingType.sleepReminder
                    ? Strings.bedtimeReminder
                    : Strings.reminderOfDailyChallangeTimes,
                isEnabled: state.isEnabled,
                onToggle: manager.toggleEnabled,
                selectedTime: state.selectedTime ?? DateTime.now(),
                onTimeChanged: manager.setSelectedTime,
                isExpanded: state.isEnabled,
                onExpandToggle: () {},
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => manager.saveSettings(type),
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
    required BuildContext context,
    required NotificationSettingSheetManager manager,
    required NotificationSettingSheetState state,
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
