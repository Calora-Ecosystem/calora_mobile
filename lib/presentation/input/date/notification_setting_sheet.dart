import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
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
    extends Managed<NotificationSettingSheetManager, NotificationSettingSheetState, NotificationSettingSheetEffect> {
  final NotificationSettingType type;
  final List<ReminderRequest> reminders;

  const NotificationSettingSheet({super.key, required this.type, required this.reminders});

  @override
  void init(BuildContext context, NotificationSettingSheetManager manager) {
    manager.init(type, reminders);
  }

  @override
  void listener(BuildContext context, NotificationSettingSheetManager manager, NotificationSettingSheetEffect effect) {
    effect.when(save: () => Navigator.pop(context));
  }

  @override
  Widget builder(BuildContext context, NotificationSettingSheetManager manager, NotificationSettingSheetState state) {
    final isMeal = type == NotificationSettingType.mealReminder;

    final List<String> waterItem = [
      Strings.every1Hour,
      Strings.every2Hour,
      Strings.every3Hour,
      Strings.every4Hour,
      Strings.every5Hour,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Strings.settingUpReminders.text(22, 28, 700).c(context.colors.textStrong),
            if (isMeal) ...[
              _mealItem(context, manager, state, 'Breakfast', Strings.breakfastTimeReminder),
              _mealItem(context, manager, state, 'Lunch', Strings.lunchTimeReminder),
              _mealItem(context, manager, state, 'Dinner', Strings.dinnerTimeReminder),
            ] else
              _singleItem(context, manager, state),
            SizedBox(
              width: double.infinity,
              child: Button(onPressed: () => manager.save(type), text: Strings.save),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _singleItem(
    BuildContext context,
    NotificationSettingSheetManager manager,
    NotificationSettingSheetState state,
  ) {
    final isWater = type == NotificationSettingType.waterReminder;

    final title = switch (type) {
      NotificationSettingType.waterReminder => Strings.waterDrinkReminder,
      NotificationSettingType.sleepReminder => Strings.bedtimeReminder,
      NotificationSettingType.thirtyDayChallenges => Strings.reminderOfDailyChallangeTimes,
      _ => '',
    };

    return _block(
      context: context,
      title: title,
      enabled: state.isEnabled,
      onToggle: manager.toggleMain,
      child: state.isEnabled
          ? (isWater
                ? _waterPicker(context, manager, state)
                : CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: state.singleTime!,
                    onDateTimeChanged: manager.setSingleTime,
                  ))
          : null,
    );
  }

  Widget _mealItem(
    BuildContext context,
    NotificationSettingSheetManager manager,
    NotificationSettingSheetState state,
    String key,
    String title,
  ) {
    final setting = state.mealTimes[key] ?? MealTimeSetting(enabled: false, time: DateTime.now());
    final time = setting.time;
    return _block(
      context: context,
      title: title,
      enabled: setting.enabled,
      onToggle: (v) => manager.toggleMeal(key, v),
      child: setting.enabled
          ? CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: time,
              onDateTimeChanged: (t) => manager.setMealTime(key, t),
            )
          : null,
    );
  }

  Widget _waterPicker(
    BuildContext context,
    NotificationSettingSheetManager manager,
    NotificationSettingSheetState state,
  ) {
    final waterItem = [
      Strings.every1Hour,
      Strings.every2Hour,
      Strings.every3Hour,
      Strings.every4Hour,
      Strings.every5Hour,
    ];

    return SizedBox(
      height: 180,
      child: CupertinoPicker(
        itemExtent: 40,
        useMagnifier: true,
        magnification: 1.1,
        scrollController: FixedExtentScrollController(initialItem: state.waterIndex ?? 0),
        onSelectedItemChanged: (i) => manager.setWaterIndex(i),
        children: waterItem
            .map(
              (e) => Center(
                child: Text(e, style: TextStyle(fontSize: 18, color: context.colors.textStrong)),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _block({
    required BuildContext context,
    required String title,
    required bool enabled,
    required Function(bool) onToggle,
    required Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.colors.backgroundElevation, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: title.text(16, 20, 400).c(context.colors.textStrong).auto(minSize: 12)),
              CustomSwitch(value: enabled, result: onToggle),
            ],
          ),
          if (enabled && child != null) ...[const SizedBox(height: 20), SizedBox(height: 180, child: child)],
        ],
      ),
    );
  }
}
