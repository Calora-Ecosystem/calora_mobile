import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/step_sources/step_connect.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HealthSyncFixDialog extends StatelessWidget {
  const HealthSyncFixDialog({
    super.key,
    required this.tracker,
    required this.onOpenTracker,
  });

  final TrackerAppStatus tracker;
  final VoidCallback onOpenTracker;

  static Future<void> show({
    required BuildContext context,
    required TrackerAppStatus tracker,
    required VoidCallback onOpenTracker,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          HealthSyncFixDialog(tracker: tracker, onOpenTracker: onOpenTracker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = tracker.name;
    return Dialog(
      backgroundColor: context.colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: TrackerLogo(id: tracker.id, size: 56)),
            const SizedBox(height: 16),
            'steps_syncfix_title'
                .tr(namedArgs: {'app': app})
                .text(18, 24, 700)
                .c(context.colors.textStrong)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 8),
            'steps_syncfix_body'
                .tr(namedArgs: {'app': app})
                .text(14, 20, 400)
                .c(context.colors.textSub)
                .copyWith(textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.accentGreenWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: trackerSetupHint(
                tracker,
              ).text(13, 19, 500).c(context.colors.textStrong),
            ),
            const SizedBox(height: 20),
            Button(
              text: 'steps_syncfix_open'.tr(namedArgs: {'app': app}),
              onPressed: () {
                Navigator.of(context).pop();
                onOpenTracker();
              },
            ),
            const SizedBox(height: 8),
            Button(
              text: 'steps_action_done'.tr(),
              type: ButtonType.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
