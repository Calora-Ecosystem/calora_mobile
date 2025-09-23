import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loadable/loadable.dart';
import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/domain/model/notification/notification_setting_type.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/input/date/date_input_page.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_manager.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/builder/notification/setting/notification_setting_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class NotificationSettingsPage
    extends
        Managed<
          NotificationSettingsManager,
          NotificationSettingsState,
          NotificationSettingsEffect
        > {
  @override
  void init(context, manager) {
    manager.getNotificationSettings();
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

  Widget _uiBuilder(
    NotificationSettingsState state,
    BuildContext context,
    NotificationSettingsManager manager,
  ) {
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
        itemCount: state.notificationSettings.length ?? 1,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final notificationSetting = state.notificationSettings[index];
          return NotificationSettingItemBuilder(
            notificationSetting: notificationSetting,
            onClickItem: (data) {
              _openInputManagePage(notificationSetting, context, manager);
            },
          );
        },
      );
    }
  }

  void _openInputManagePage(
    NotificationSetting notificationSetting,
    BuildContext context,
    NotificationSettingsManager manager,
  ) {
    switch (notificationSetting.type) {
      case NotificationSettingType.mealReminder:
        _showNotificationSettingsSheet(context, NotificationSettingType.mealReminder);
        break;
      case NotificationSettingType.waterReminder:
        _showNotificationSettingsSheet(context, NotificationSettingType.waterReminder);
        break;
      case NotificationSettingType.sleepReminder:
        _showNotificationSettingsSheet(context, NotificationSettingType.sleepReminder);
        break;
      case NotificationSettingType.thirtyDayChallenges:
        _showNotificationSettingsSheet(context, NotificationSettingType.thirtyDayChallenges);
        break;
      default:
        break;
    }
  }

  void _showNotificationSettingsSheet(BuildContext context, NotificationSettingType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return NotificationSettingSheet(type: type, onSave: (times) {});
      },
    );
  }

  void _dismiss(BuildContext context) {
    Navigator.pop(context);
  }

  void _back(BuildContext context) {
    return context.router.pop();
  }
}
