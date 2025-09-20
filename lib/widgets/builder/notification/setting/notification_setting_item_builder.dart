import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/notification/notificaiton_setting.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class NotificationSettingItemBuilder extends StatelessWidget {
  final NotificationSetting notificationSetting;

  final Function(NotificationSetting) onClickItem;

  const NotificationSettingItemBuilder({
    super.key,
    required this.notificationSetting,
    required this.onClickItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      title: notificationSetting.title
          .text(14, 16, 400)
          .c(context.colors.textStrong),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          Assets.icons.icForward.svg(
            colorFilter: ColorFilter.mode(
              context.colors.black,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
      onTap: () => onClickItem(notificationSetting),
    );
  }
}
