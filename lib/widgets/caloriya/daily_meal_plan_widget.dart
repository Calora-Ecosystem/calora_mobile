import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/citation/citation_link.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class DailyMealPlanWidget extends StatelessWidget {
  final String accordingToPlan;
  final String consumed;
  final String leftover;
  final bool loading;

  const DailyMealPlanWidget({
    super.key,
    required this.accordingToPlan,
    required this.consumed,
    required this.leftover,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Strings.dailyMealPlan.text(20, 24, 600).c(context.colors.textStrong),
          _tile(
            textColor: context.colors.textStrong,
            context,
            icon: Assets.icons.icSms.svg(),
            title: Strings.accordingToPlan,
            value: accordingToPlan,
            loading: loading,
          ),
          _tile(
            textColor: context.colors.textStrong,
            context,
            icon: Assets.icons.icDoneCircle.svg(),
            title: Strings.foodConsumed,
            value: consumed,
            loading: loading,
          ),
          _tile(
            textColor: double.parse(leftover) < 0
                ? context.colors.red
                : context.colors.textStrong,
            context,
            icon: Assets.icons.icFood.svg(),
            title: Strings.leftoverFoodPlan,
            value: leftover.toString(),
            loading: loading,
          ),
          const CitationLink(
            url: 'https://www.calculator.net/calorie-calculator.html',
            label: 'calculator.net',
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String value,
    required bool loading,
    required Color textColor,
  }) {
    return ShimmerWrapper(
      loading: loading,
      shimmerChild: ShimmerChild(height: 52),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.accentSub,
                borderRadius: BorderRadius.circular(12),
              ),
              child: icon,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: title
                  .text(14, 16, 400)
                  .c(context.colors.textSub)
                  .auto(maxLines: 2, minSize: 14),
            ),
            Spacer(),
            Row(
              children: [
                value.text(20, 24, 600).c(textColor).auto(minSize: 16),
                const SizedBox(width: 4),
                Strings.kcal
                    .text(20, 24, 600)
                    .c(context.colors.textSub)
                    .copyWith(
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    )
                    .auto(minSize: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
