import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/nutrient/nutrient_data.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class DailyFeedRateWidget extends StatelessWidget {
  final String normCalories;
  final String remainedCalories;
  final double progressPercent;
  final List<NutrientInfo> nutrients;
  final VoidCallback onAddFoodTap;

  const DailyFeedRateWidget({
    super.key,
    required this.normCalories,
    required this.remainedCalories,
    required this.progressPercent,
    required this.nutrients,
    required this.onAddFoodTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: context.colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Strings.dailyFeedRate.text(20, 24, 600),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                spacing: 8,
                children: [
                  Strings.norm.text(14, 16, 400),
                  Row(spacing: 4, children: [normCalories.text(16, 20, 500), 'kkal'.text(12, 14, 400)]),
                ],
              ),
              SizedBox(
                height: 100,
                width: 100,
                child: CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 10,
                  percent: safePercent(progressPercent),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: context.colors.accentSub,
                  backgroundColor: context.colors.backgroundElevation,
                  center: '${(safePercent(progressPercent) * 100).round()}%'
                      .text(16, 20, 500)
                      .c(context.colors.textStrong),
                ),
              ),
              Column(
                spacing: 8,
                children: [
                  Strings.remained.text(14, 16, 400),
                  Row(spacing: 4, children: [remainedCalories.text(16, 20, 500), 'kkal'.text(12, 14, 400)]),
                ],
              ),
            ],
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
                      animation: true,
                      percent: nutrient.percent,
                      lineHeight: 8,
                      progressColor: context.colors.blueAccent,
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
          GestureDetector(
            onTap: onAddFoodTap,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 6),
              width: double.infinity,
              decoration: BoxDecoration(color: context.colors.accentSub, borderRadius: BorderRadius.circular(16)),
              child: Strings.addFood.text(16, 20, 500).c(context.colors.white).copyWith(textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  double safePercent(double percent) {
    if (percent.isNaN || percent.isInfinite) return 0.0;
    if (percent < 0) return 0.0;
    if (percent > 1) return 1.0;
    return percent;
  }
}
