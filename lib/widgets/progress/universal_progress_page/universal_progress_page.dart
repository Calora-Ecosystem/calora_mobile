import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'management/universal_progress_management.dart';
import 'management/universal_progress_manager.dart';

@RoutePage()
class UniversalProgressPage extends Managed<UniversalProgressManager, UniversalProgressState, UniversalProgressEffect> {
  final String title;
  final String description;
  final VoidCallback? onComplete;

  final List<String> steps;

  const UniversalProgressPage(this.description, {super.key, required this.title, required this.steps, this.onComplete});

  @override
  void init(BuildContext context, UniversalProgressManager manager) {
    super.init(context, manager);
    manager.startProgressAnimation(onComplete: onComplete);
  }

  @override
  void listener(BuildContext context, UniversalProgressManager manager, UniversalProgressEffect effect) {
    super.listener(context, manager, effect);
    effect.mapOrNull(
      completed: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.router.pop(true);
        });
      },
    );
  }

  @override
  Widget builder(BuildContext context, UniversalProgressManager manager, UniversalProgressState state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(
        title: title.text(16, 20, 500).c(context.colors.textStrong),
        onBack: () => context.router.pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.backgroundElevation,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Assets.icons.informationCircleBlue.svg(),
                  Expanded(child: description.text(16, 20, 500).c(context.colors.brightBlue)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CircularPercentIndicator(
              radius: 90,
              lineWidth: 18,
              percent: state.progress.clamp(0.0, 1.0),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: context.colors.accentSub,
              backgroundColor: context.colors.backgroundElevation,
              center: '${(state.progress * 100).round()}%'.text(32, 40, 700).c(context.colors.textStrong),
            ),
            const SizedBox(height: 40),
            ...List.generate(steps.length, (index) {
              final threshold = (index + 1) / steps.length;
              final isDone = state.progress >= threshold;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.commonBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      isDone
                          ? Assets.icons.done.svg(width: 24, height: 24)
                          : const CupertinoActivityIndicator(radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: steps[index]
                            .text(14, 18, 400)
                            .c(isDone ? context.colors.textSub : context.colors.textStrong),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
