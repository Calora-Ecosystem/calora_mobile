import 'dart:io';

import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/step_sources/step_sources_page.dart';
import 'package:calora/widgets/health/health_sync_bottom_sheet.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class StepConnectOutcome {
  const StepConnectOutcome(this.result, {this.trackerNeedsSetup});

  final HealthConnectConnectResult result;
  final TrackerAppStatus? trackerNeedsSetup;

  bool get connected => result == HealthConnectConnectResult.connected;
}

Future<StepConnectOutcome> linkHealthConnect(
  StepCounterService stepCounter, {
  String? trackerId,
}) async {
  final result = await CaloraSteps.connectHealthConnect();
  if (result != HealthConnectConnectResult.connected) {
    return StepConnectOutcome(result);
  }
  await stepCounter.refresh();
  if (trackerId == null) return StepConnectOutcome(result);
  final status = await CaloraSteps.status();
  final tracker = status.trackers.firstWhereOrNull((t) => t.id == trackerId);
  return StepConnectOutcome(
    result,
    trackerNeedsSetup: tracker != null && !tracker.syncing ? tracker : null,
  );
}

String trackerSetupHint(TrackerAppStatus tracker) => switch (tracker.id) {
  'samsung_health' => 'steps_sources_app_hint_samsung'.tr(),
  'google_fit' => 'steps_sources_app_hint_fit'.tr(),
  _ => 'steps_sources_app_hint_generic'.tr(namedArgs: {'app': tracker.name}),
};

Future<void> openStepTracking(BuildContext context) {
  if (Platform.isAndroid) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const StepSourcesPage()));
  }
  return HealthSyncBottomSheet.show(context);
}

class TrackerLogo extends StatelessWidget {
  const TrackerLogo({super.key, required this.id, this.size = 40});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = switch (id) {
      'samsung_health' => Assets.images.health,
      'google_fit' => Assets.images.googleFit,
      'garmin' => Assets.images.garmin,
      _ => null,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: SizedBox.square(
        dimension: size,
        child: image != null
            ? image.image(fit: BoxFit.cover)
            : ColoredBox(
                color: context.colors.accentGreenWhite,
                child: Icon(
                  Icons.watch_rounded,
                  size: size * 0.55,
                  color: context.colors.accentSub,
                ),
              ),
      ),
    );
  }
}

class HealthConnectLogo extends StatelessWidget {
  const HealthConnectLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.favorite_rounded,
        size: size * 0.55,
        color: const Color(0xFF1A73E8),
      ),
    );
  }
}
