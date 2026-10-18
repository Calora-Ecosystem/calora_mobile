import 'dart:io';

import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/step_sources/step_connect.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class StepTrackingTile extends StatelessWidget {
  const StepTrackingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = getIt<StepCounterService>();
    return StreamBuilder<StepSnapshot>(
      stream: counter.snapshots,
      initialData: counter.lastSnapshot,
      builder: (context, snapshot) {
        final problem =
            Platform.isAndroid && isStepCountingBlocked(snapshot.data?.issue);
        final title = Platform.isIOS
            ? 'Apple Health'
            : 'steps_sources_title'.tr();
        final subtitle = problem
            ? 'steps_sources_counting_problem'.tr()
            : Platform.isIOS
            ? 'steps_ios_body'.tr()
            : 'steps_sources_counting_ok'.tr();
        return Material(
          color: context.colors.backgroundElevation,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openStepTracking(context),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Platform.isIOS
                          ? Assets.images.iosHealth.image(fit: BoxFit.cover)
                          : ColoredBox(
                              color: context.colors.accentGreenWhite,
                              child: Icon(
                                Icons.directions_walk_rounded,
                                color: context.colors.accentSub,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title.text(15, 20, 600).c(context.colors.textStrong),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 18 / 13,
                            color: problem
                                ? context.colors.errorBase
                                : context.colors.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.iconSub,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

bool isStepCountingBlocked(StepIssue? issue) =>
    issue == StepIssue.activityPermission || issue == StepIssue.noSource;
