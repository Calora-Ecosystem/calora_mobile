import 'package:calora/common/enums/notification_setting_type.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/sheets/default_bottom_sheet.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_management.dart';
import 'package:calora/presentation/notification/settings/management/notification_settings_manager.dart';
import 'package:calora/presentation/notification/settings/widgets/food_notification_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class CaloryNotificationSettings
    extends
        Managed<
          NotificationSettingsManager,
          NotificationSettingsState,
          NotificationSettingsEffect
        > {
  const CaloryNotificationSettings({super.key});

  @override
  Widget builder(context, manager, state) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => DefaultBottomSheet(
            padding: EdgeInsets.zero,
            title: ReminderSettingTypeEnum.food.displayName,
            child: FoodNotificationSettingsSheet(
              manager: manager,
              loading: state.loading,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.backgroundElevation,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Assets.icons.greenNotification.svg(),
                const SizedBox(width: 8),
                Strings.notification
                    .text(20, 24, 600)
                    .c(context.colors.textStrong),
                Spacer(),
                Assets.icons.setting.svg(),
              ],
            ),
            const SizedBox(height: 4),
            Strings.toRemindYouOfMealTimes
                .text(14, 16, 400)
                .c(context.colors.textSub),
          ],
        ),
      ),
    );
  }
}
