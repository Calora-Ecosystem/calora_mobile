import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/manager_builder.dart';
import 'package:calora/common/enums/menu_type_enum.dart';
import 'package:calora/common/enums/notification_setting_type.dart';
import 'package:calora/common/enums/reminder_types_enum.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/containers/bottom_box.dart';
import 'package:calora/common/widgets/loadable/loadable.dart';
import 'package:calora/domain/model/reminder/reminder_request.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_manager.dart';
import 'package:calora/presentation/notification/settings/widgets/_build_reminder_item.dart';
import 'package:flutter/material.dart';

class FoodNotificationSettingsSheet extends StatefulWidget {
  final NotificationSettingsManager manager;
  final bool loading;
  const FoodNotificationSettingsSheet({super.key, required this.manager, this.loading = false});

  @override
  State<FoodNotificationSettingsSheet> createState() => _FoodNotificationSettingsSheetState();
}

class _FoodNotificationSettingsSheetState extends State<FoodNotificationSettingsSheet> {
  late Map<ReminderTypesEnum, ReminderRequest> _originalReminders;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _originalReminders = Map.from(widget.manager.state.reminders);
  }

  @override
  void dispose() {
    if (!_isSaved) {
      widget.manager.setReminders(_originalReminders);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ManagerBuilder<NotificationSettingsState, NotificationSettingsEffect>(
      manager: widget.manager,
      properties: (state) => [state.reminders, state.isSaving],
      builder: (context, state) {
        return Loadable(
          loading: widget.loading,
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 16,
                      children: [
                        buildReminderItem(
                          title: Strings.breakfastTimeReminder,
                          typeEnum: ReminderTypesEnum.breakfast,
                          settingType: ReminderSettingTypeEnum.food,
                          menuEnum: MenuTypeEnum.breakfast,
                          state: state,
                          manager: widget.manager,
                        ),
                        buildReminderItem(
                          title: Strings.lunchTimeReminder,
                          typeEnum: ReminderTypesEnum.lunch,
                          settingType: ReminderSettingTypeEnum.food,
                          menuEnum: MenuTypeEnum.lunch,
                          state: state,
                          manager: widget.manager,
                        ),
                        buildReminderItem(
                          title: Strings.dinnerTimeReminder,
                          typeEnum: ReminderTypesEnum.dinner,
                          settingType: ReminderSettingTypeEnum.food,
                          menuEnum: MenuTypeEnum.dinner,
                          state: state,
                          manager: widget.manager,
                        ),
                        buildReminderItem(
                          title: Strings.snackTimeReminder,
                          typeEnum: ReminderTypesEnum.snack,
                          settingType: ReminderSettingTypeEnum.food,
                          menuEnum: MenuTypeEnum.snack,
                          state: state,
                          manager: widget.manager,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                BottomBox(
                  child: Button(
                    text: Strings.save,
                    loading: state.isSaving,
                    onPressed: () async {
                      _isSaved = true;
                      await widget.manager.saveAllReminderChanges(originalReminders: _originalReminders);
                      if (context.mounted) context.router.maybePop();
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
