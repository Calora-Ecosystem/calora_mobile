import 'package:calora/common/enums/menu_type_enum.dart';
import 'package:calora/common/enums/notification_setting_type.dart';
import 'package:calora/common/enums/reminder_types_enum.dart';
import 'package:calora/domain/model/reminder/reminder_request.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_manager.dart';
import 'package:calora/widgets/notification_widgets/notification_expandable_item.dart';
import 'package:flutter/material.dart';

Widget buildReminderItem({
  required String title,
  required ReminderTypesEnum typeEnum,
  required ReminderSettingTypeEnum settingType,
  MenuTypeEnum? menuEnum,
  required NotificationSettingsState state,
  required NotificationSettingsManager manager,
  bool isInterval = false,
}) {
  final reminder = state.reminders[typeEnum];
  final isEnabled = reminder != null;
  var time = reminder?.time;

  if (time != null && time.length > 5) {
    time = time.substring(0, 5);
  }

  return NotificationExpandableItem(
    title: title,
    isInterval: isInterval,
    initialEnabled: isEnabled,
    initialTime: time,
    onChanged: (isOn, newTime) {
      if (isOn) {
        manager.updateReminder(
          typeEnum,
          ReminderRequest(id: reminder?.id, time: newTime, type: settingType.toApi, menu: menuEnum?.toApi),
        );
      } else {
        manager.removeReminder(typeEnum);
      }
    },
  );
}
