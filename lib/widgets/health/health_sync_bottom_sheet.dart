import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthSyncBottomSheet extends StatelessWidget {
  const HealthSyncBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const HealthSyncBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.strokeSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox.square(
                dimension: 64,
                child: Assets.images.iosHealth.image(fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            'Apple Health'.text(20, 26, 700).c(context.colors.primarySolid),
            const SizedBox(height: 12),
            'steps_ios_body'
                .tr()
                .text(14, 21, 400)
                .c(context.colors.textSub)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 28),
            Button(
              text: 'steps_action_settings'.tr(),
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
            ),
            const SizedBox(height: 8),
            Button(
              text: 'later'.tr(),
              type: ButtonType.secondary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
