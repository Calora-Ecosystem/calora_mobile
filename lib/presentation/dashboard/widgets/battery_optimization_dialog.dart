import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BatteryOptimizationDialog extends StatelessWidget {
  const BatteryOptimizationDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BatteryOptimizationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.accentGreenWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.battery_charging_full_rounded,
                color: context.colors.accentSub,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            'battery_hint_title'
                .tr()
                .text(18, 24, 700)
                .c(context.colors.textStrong)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 8),
            'battery_hint_body'
                .tr()
                .text(14, 20, 400)
                .c(context.colors.textSub)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Button(
              text: 'battery_hint_allow'.tr(),
              onPressed: () {
                Navigator.pop(context);
                CaloraSteps.requestIgnoreBatteryOptimizations();
              },
            ),
            const SizedBox(height: 8),
            Button(
              text: 'battery_hint_autostart'.tr(),
              type: ButtonType.secondary,
              onPressed: () {
                Navigator.pop(context);
                CaloraSteps.openAutoStart();
              },
            ),
            const SizedBox(height: 4),
            Button(
              text: Strings.later,
              height: 44,
              backgroundColor: Colors.transparent,
              foregroundColor: context.colors.textSub,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
