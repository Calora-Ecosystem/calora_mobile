import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class SettingsCard extends StatelessWidget {
  final VoidCallback onAccountTap;
  final VoidCallback onNormsTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onInviteTap;
  final VoidCallback onAboutTap;
  final VoidCallback onHelpTap;

  const SettingsCard({
    super.key,
    required this.onAccountTap,
    required this.onNormsTap,
    required this.onLanguageTap,
    required this.onNotificationsTap,
    required this.onInviteTap,
    required this.onAboutTap,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Assets.icons.userList.svg(),
        'title': Strings.accountInformation,
        'onTap': onAccountTap,
      },
      {
        'icon': Assets.icons.norms.svg(),
        'title': Strings.norms,
        'onTap': onNormsTap,
      },
      {
        'icon': Assets.icons.languageSquare.svg(),
        'title': Strings.applicationLanguage,
        'onTap': onLanguageTap,
      },
      {
        'icon': Assets.icons.notification.svg(),
        'title': Strings.settingUpNotification,
        'onTap': onNotificationsTap,
      },
      {
        'icon': Assets.icons.addTeam.svg(),
        'title': Strings.makeAnOffer,
        'onTap': onInviteTap,
      },
      {
        'icon': Assets.icons.informationCircle.svg(),
        'title': Strings.aboutCalora,
        'onTap': onAboutTap,
      },
      {
        'icon': Assets.icons.messageQuestion.svg(),
        'title': Strings.help,
        'onTap': onHelpTap,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Container(
              decoration: BoxDecoration(
                color: context.colors.backgroundElevation,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: item['icon'] as Widget,
            ),
            title: item['title']
                .toString()
                .text(14, 16, 400)
                .c(context.colors.textStrong),
            trailing: Assets.icons.arrowRight.svg(),
            onTap: item['onTap'] as VoidCallback,
          );
        },
      ),
    );
  }
}
