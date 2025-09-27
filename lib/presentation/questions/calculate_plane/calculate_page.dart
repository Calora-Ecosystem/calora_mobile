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
class CalculatePage extends Managed<CalculateManager, CalculateState, CalculateEffect> {
  const CalculatePage({super.key});

  @override
  Widget builder(BuildContext context, CalculateManager manager, CalculateState state) {
    return _CalculateContent();
  }
}

class _CalculateContent extends StatefulWidget {
  @override
  State<_CalculateContent> createState() => _CalculateContentState();
}

class _CalculateContentState extends State<_CalculateContent> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<double> doneThresholds = [0.3, 0.6, 1.0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10));

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget analyzingItem(BuildContext context, String text, double threshold) {
    bool done = _animation.value >= threshold;
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
  Widget build(BuildContext context) {
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
                        color: Colors.black.withOpacity(0.2),
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
                          percent: _animation.value,
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: context.colors.accentSub,
                          backgroundColor: context.colors.backgroundElevation,
                          center: '${(_animation.value * 100).round()}%'
                              .text(32, 40, 700)
                              .c(context.colors.textStrong),
                        ),
                      ),
                      const SizedBox(height: 20),
                      analyzingItem(context, Strings.analyzingActivityLevel, doneThresholds[0]),
                      const SizedBox(height: 16),
                      analyzingItem(context, Strings.smartReminderPlan, doneThresholds[1]),
                      const SizedBox(height: 16),
                      analyzingItem(context, Strings.analyzingActivityLevel, doneThresholds[2]),
                    ],
                  ),
                ),
                if (_animation.value == 1)
                  GestureDetector(
                    onTap: () {},
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
