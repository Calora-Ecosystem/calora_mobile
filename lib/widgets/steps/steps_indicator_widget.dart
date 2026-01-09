import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class StepsIndicatorWidget extends StatelessWidget {
  final double current;
  final int goal;
  final VoidCallback? onEditTap;

  const StepsIndicatorWidget({
    super.key,
    required this.current,
    required this.goal,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / goal).clamp(0.0, 1.0);

    return CircularPercentIndicator(
      radius: 100,
      lineWidth: 15,
      animation: true,
      animationDuration: 2000,
      percent: progress,
      backgroundColor: context.colors.progressBackground,
      progressColor: context.colors.blueAccent,
      circularStrokeCap: CircularStrokeCap.round,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Assets.icons.stepsHuman.svg(),
          const SizedBox(height: 8),
          current
              .toInt()
              .toString()
              .text(32, 40, 700)
              .c(context.colors.textStrong),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onEditTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ('${Strings.goal}:$goal')
                    .text(14, 16, 600)
                    .c(context.colors.textSub),
                Assets.icons.edit.svg(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
