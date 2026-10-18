import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/step_sources/step_connect.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class StepTrackerConnectSheet extends StatelessWidget {
  const StepTrackerConnectSheet({
    super.key,
    required this.tracker,
    required this.availability,
  });

  final TrackerAppStatus? tracker;
  final HealthConnectAvailability availability;

  static Future<bool> show(
    BuildContext context, {
    required TrackerAppStatus? tracker,
    required HealthConnectAvailability availability,
  }) async {
    final accepted = await context.showAppBottomSheet<bool>(
      child: StepTrackerConnectSheet(
        tracker: tracker,
        availability: availability,
      ),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final app = tracker?.name;
    final body = app == null
        ? 'steps_connect_body_generic'.tr()
        : 'steps_connect_body'.tr(namedArgs: {'app': app});
    final note = availability.canBeInstalled
        ? 'steps_connect_install_note'.tr()
        : 'steps_connect_note'.tr();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 56,
                  height: 56,
                  color: context.colors.accentGreenWhite,
                  padding: const EdgeInsets.all(8),
                  child: Assets.images.caloraLogo.image(fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.sync_alt_rounded,
                  color: context.colors.iconSoft,
                ),
              ),
              tracker != null
                  ? TrackerLogo(id: tracker!.id, size: 56)
                  : const HealthConnectLogo(size: 56),
            ],
          ),
          const SizedBox(height: 20),
          'steps_connect_title'
              .tr(namedArgs: {'app': app ?? 'Health Connect'})
              .text(20, 26, 700)
              .c(context.colors.textStrong)
              .copyWith(textAlign: TextAlign.center),
          const SizedBox(height: 10),
          body
              .text(14, 20, 400)
              .c(context.colors.textSub)
              .copyWith(textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _Benefit(text: 'steps_connect_benefit_watch'.tr()),
          if (app != null)
            _Benefit(
              text: 'steps_connect_benefit_sync'.tr(namedArgs: {'app': app}),
            ),
          _Benefit(text: 'steps_connect_benefit_safe'.tr()),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.informationLighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: context.colors.informationBase,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: note.text(13, 18, 400).c(context.colors.textStrong),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Button(
            text: availability.canBeInstalled
                ? 'steps_action_install'.tr()
                : 'steps_action_connect'.tr(),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          Button(
            text: 'later'.tr(),
            type: ButtonType.secondary,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: context.colors.accentSub,
          ),
          const SizedBox(width: 10),
          Expanded(child: text.text(14, 18, 500).c(context.colors.textStrong)),
        ],
      ),
    );
  }
}
