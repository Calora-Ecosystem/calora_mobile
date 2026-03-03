import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/nutrient/nutrient_data.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DailyFeedRateWidget extends StatelessWidget {
  final String normCalories;
  final double remainedCalories;
  final double progressPercent;
  final List<NutrientInfo> nutrients;
  final VoidCallback onAddFoodTap;
  final bool loading;

  const DailyFeedRateWidget({
    super.key,
    required this.normCalories,
    required this.remainedCalories,
    required this.progressPercent,
    required this.nutrients,
    required this.onAddFoodTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final allNutrientsDone = nutrients.isNotEmpty && nutrients.every((n) => n.percent.clamp(0.0, 1.0) == 1.0);
    final caloriesDone = remainedCalories <= 0;
    final hideAddFoodButton = allNutrientsDone && caloriesDone;
    return ShimmerWrapper(
      loading: loading,
      shimmerChild: const ShimmerChild(height: 272, radius: 20),
      child: Container(
        // height: 272,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Strings.dailyFeedRate.text(18, 24, 600),
            SizedBox(
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: CircularPercentIndicator(
                      animateFromLastPercent: true,
                      radius: 50,
                      lineWidth: 10,
                      percent: safePercent(progressPercent),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: safePercent(progressPercent) >= 1 ? context.colors.red : context.colors.accentSub,
                      backgroundColor: context.colors.backgroundElevation,
                      center: '${(safePercent(progressPercent) * 100).round()}%'
                          .text(16, 20, 500)
                          .c(context.colors.textStrong),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _SideCalories(title: Strings.norm, value: normCalories),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _SideCalories(
                      title: remainedCalories < 0 ? Strings.excess : Strings.remained,
                      value: remainedCalories.abs().asFixedTruncated(0),
                      alignRight: true,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              spacing: 16,
              children: nutrients.map((nutrient) {
                return Expanded(
                  child: Column(
                    spacing: 8,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          nutrient.value.asFixedTruncated(1).toString().text(16, 20, 500),
                          'gr'.text(12, 14, 400),
                        ],
                      ),
                      LinearPercentIndicator(
                        animateFromLastPercent: true,
                        animation: true,
                        percent: nutrient.percent.clamp(0, 1),
                        lineHeight: 8,
                        progressColor: nutrient.percent.clamp(0, 1) >= 1
                            ? context.colors.red
                            : context.colors.blueAccent,
                        backgroundColor: context.colors.backgroundElevation,
                        padding: EdgeInsets.zero,
                        barRadius: const Radius.circular(6),
                      ),
                      nutrient.name.text(14, 16, 400),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (!hideAddFoodButton)
              GestureDetector(
                onTap: onAddFoodTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: context.colors.accentSub, borderRadius: BorderRadius.circular(16)),
                  child: Strings.addFood
                      .text(16, 20, 500)
                      .c(context.colors.white)
                      .copyWith(textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double safePercent(double percent) {
    if (percent.isNaN || percent.isInfinite) return 0;
    return percent.clamp(0, 1);
  }
}

class _SideCalories extends StatelessWidget {
  final String title;
  final String value;
  final bool alignRight;

  const _SideCalories({required this.title, required this.value, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 90),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 6,
        children: [
          title.text(14, 16, 400).copyWith(maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: value.text(16, 20, 500).copyWith(maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              Strings.kcal.text(12, 14, 400),
            ],
          ),
        ],
      ),
    );
  }
}
