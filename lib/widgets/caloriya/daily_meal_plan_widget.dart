import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class DailyMealPlanWidget extends StatelessWidget {
  final String accordingToPlan;
  final String consumed;
  final String leftover;

  const DailyMealPlanWidget({super.key, required this.accordingToPlan, required this.consumed, required this.leftover});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.colors.backgroundElevation, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Strings.dailyMealPlan.text(20, 24, 600).c(context.colors.textStrong),
          _tile(context, icon: Assets.icons.icSms.svg(), title: Strings.accordingToPlan, value: accordingToPlan),
          _tile(context, icon: Assets.icons.icDoneCircle.svg(), title: Strings.foodConsumed, value: consumed),
          _tile(context, icon: Assets.icons.icFood.svg(), title: Strings.leftoverFoodPlan, value: leftover),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, {required Widget icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: context.colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: context.colors.accentSub, borderRadius: BorderRadius.circular(12)),
            child: icon,
          ),
          const SizedBox(width: 8),
          title.text(14, 16, 400).c(context.colors.textSub),
          Spacer(),
          Row(
            children: [
              value.text(20, 24, 600).c(context.colors.textStrong).auto(maxLines: 1, minSize: 16),
              const SizedBox(width: 4),
              'kkal'
                  .text(20, 24, 600)
                  .c(context.colors.textSub)
                  .copyWith(textAlign: TextAlign.end)
                  .auto(maxLines: 1, minSize: 16),
            ],
          ),
        ],
      ),
    );
  }
}
