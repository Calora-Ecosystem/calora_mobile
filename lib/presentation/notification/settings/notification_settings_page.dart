// notification_settings_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loadable/loadable.dart';
import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/domain/model/notification/reminder_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/input/date/notification_setting_sheet.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_manager.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/builder/notification/setting/notification_setting_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class NotificationSettingsPage
    extends Managed<NotificationSettingsManager, NotificationSettingsState, NotificationSettingsEffect> {
  @override
  void init(context, manager) {
    manager.getNotificationSettings();
    manager.getReminders();
  }

  @override
  void listener(context, manager, effect) {}

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(
        title: Strings.settingUpNotification,
        onBack: () {
          _back(context);
        },
      ),
      body: _uiBuilder(state, context, manager),
    );
  }

  Widget _uiBuilder(NotificationSettingsState state, BuildContext context, NotificationSettingsManager manager) {
    if (state.loading) {
      return Loadable(
        builder: (context) {
          return SizedBox();
        },
      );
    } else {
      return ListView.separated(
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: context.colors.strokeSoft),
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: state.notificationSettings.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final notificationSetting = state.notificationSettings[index];
          return NotificationSettingItemBuilder(
            notificationSetting: notificationSetting,
            onClickItem: (data) {
              _openInputManagePage(notificationSetting, context, state.reminders);
            },
          );
        },
      );
    }
  }

  void _openInputManagePage(
    NotificationSetting notificationSetting,
    BuildContext context,
    List<ReminderRequest> reminders,
  ) {
    context.showAppBottomSheet(
      initialChildSize: 0.6,
      child: NotificationSettingSheet(type: notificationSetting.type, reminders: reminders),
    );
  }

  void _back(BuildContext context) {
    context.router.pop();
  }
}
