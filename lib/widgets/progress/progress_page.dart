import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/questions/calculate_plane/management/calculate_management.dart';
import 'package:calora/presentation/questions/calculate_plane/management/calculate_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

@RoutePage()
class ProgressPage extends Managed<CalculateManager, CalculateState, CalculateEffect> {
  final bool fetchGoals;
  final int mode;
  final PageRouteInfo? nextRoute;

  const ProgressPage({super.key, this.mode = 1, this.nextRoute, this.fetchGoals = false});

  @override
  void init(BuildContext context, CalculateManager manager) {
    super.init(context, manager);
    if (fetchGoals) {
      var result = manager.getDailyGoals();
    }
    manager.startProgressAnimation(
      onComplete: () {
        if (mode == 2 && nextRoute != null) {
          context.router.replace(nextRoute!);
        }
      },
    );
  }

  @override
  void listener(BuildContext context, CalculateManager manager, CalculateEffect effect) {
    effect.when(
      error: (message) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
      navigateNext: () {
        if (nextRoute != null) {
          context.router.replace(nextRoute!);
        } else {
          context.router.pop();
        }
      },
    );
  }

  Widget _analyzingItem(
    BuildContext context,
    String text,
    double threshold,
    double currentProgress,
  ) {
    bool done = currentProgress >= threshold;
    Color textColor = done ? context.colors.textSub : context.colors.textStrong;

    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.commonBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          done ? Assets.icons.done.svg() : const CupertinoActivityIndicator(radius: 12),
          const SizedBox(width: 8),
          Expanded(child: text.text(14, 16, 400).c(textColor)),
        ],
      ),
    );
  }

  @override
  Widget builder(BuildContext context, CalculateManager manager, CalculateState state) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, top: 80),
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    color: context.colors.accentWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 300,
                        child: Strings.planningDailySchedule
                            .text(16, 20, 500)
                            .c(context.colors.textStrong)
                            .copyWith(maxLines: 2),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: CircularPercentIndicator(
                          radius: 80,
                          lineWidth: 16,
                          percent: state.progressPercent,
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: context.colors.accentSub,
                          backgroundColor: context.colors.backgroundElevation,
                          center: '${(state.progressPercent * 100).round()}%'
                              .text(32, 40, 700)
                              .c(context.colors.textStrong),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _analyzingItem(
                        context,
                        Strings.analyzingActivityLevel,
                        0.3,
                        state.progressPercent,
                      ),
                      const SizedBox(height: 16),
                      _analyzingItem(
                        context,
                        Strings.smartReminderPlan,
                        0.5,
                        state.progressPercent,
                      ),
                      const SizedBox(height: 16),
                      _analyzingItem(
                        context,
                        Strings.analyzingActivityLevel,
                        0.8,
                        state.progressPercent,
                      ),
                    ],
                  ),
                ),
                if (mode == 1 && state.progressPercent >= 1.0)
                  GestureDetector(
                    onTap: () => manager.goToNextPage(),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.colors.accentSub,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Strings.next
                          .text(16, 20, 500)
                          .c(context.colors.textWhite)
                          .copyWith(textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
