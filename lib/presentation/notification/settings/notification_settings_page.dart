import 'package:auto_route/auto_route.dart';
import 'package:calora/common/enums/notification_setting_type.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/sheets/default_bottom_sheet.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_manager.dart';
import 'package:calora/presentation/notification/settings/widgets/daily_challanges_settings_sheet.dart';
import 'package:calora/presentation/notification/settings/widgets/food_notification_settings_sheet.dart';
import 'package:calora/presentation/notification/settings/widgets/sleep_notifications_settings_sheet.dart';
import 'package:calora/presentation/notification/settings/widgets/water_notification_settings_sheet.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/builder/notification/setting/notification_setting_item_builder.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class NotificationSettingsPage
    extends Managed<NotificationSettingsManager, NotificationSettingsState, NotificationSettingsEffect> {
  const NotificationSettingsPage({super.key});

  static const _settings = [
    ReminderSettingTypeEnum.food,
    ReminderSettingTypeEnum.water,
    ReminderSettingTypeEnum.sleep,
    ReminderSettingTypeEnum.dailyChallenge,
  ];

  @override
  void init(BuildContext context, NotificationSettingsManager manager) {}

  @override
  void listener(BuildContext context, NotificationSettingsManager manager, NotificationSettingsEffect effect) {}

  @override
  Widget builder(BuildContext context, NotificationSettingsManager manager, NotificationSettingsState state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(title: Strings.settingUpNotification, onBack: () => context.router.pop()),
      body: ListView.separated(
        padding: const EdgeInsets.only(top: 16),
        itemCount: _settings.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(thickness: 1, color: context.colors.strokeSoft),
        ),
        itemBuilder: (context, index) {
          final type = _settings[index];
          return NotificationSettingItemBuilder(
            notificationName: type.displayName,
            onClickItem: () => _onItemClick(context: context, type: type, manager: manager),
          );
        },
      ),
    );
  }

  void _onItemClick({
    required BuildContext context,
    required ReminderSettingTypeEnum type,
    required NotificationSettingsManager manager,
  }) {
    if (type.isFood)
      _showBottomSheet(
        context: context,
        title: type.displayName,
        child: FoodNotificationSettingsSheet(manager: manager),
      );
    else if (type.isWater) {
      _showBottomSheet(
        context: context,
        title: type.displayName,
        child: WaterNotificationSettingsSheet(manager: manager),
      );
    } else if (type.isSleep) {
      _showBottomSheet(
        context: context,
        title: type.displayName,
        child: SleepNotificationSettingsSheet(manager: manager),
      );
    } else if (type.isDailyChallenge) {
      _showBottomSheet(
        context: context,
        title: type.displayName,
        child: DailyChallengesNotificationSettingsSheet(manager: manager),
      );
    }
  }

  void _showBottomSheet({required BuildContext context, required Widget child, required String title}) {
    final manager = context.read<NotificationSettingsManager>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DefaultBottomSheet(padding: EdgeInsets.zero, title: title, child: child),
    );
  }
}
