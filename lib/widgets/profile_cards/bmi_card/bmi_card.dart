import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/profile_cards/bmi_card/color_level_bar.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class BmiCard extends StatelessWidget {
  final double bmi;
  final double weight;
  final double targetWeight;

  const BmiCard({super.key, required this.bmi, required this.weight, required this.targetWeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Strings.bodyMassIndex.text(16, 20, 500).c(context.colors.textStrong),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                formatBmi(bmi).text(20, 24, 600).c(context.colors.textStrong),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.errorLighter,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: getBmiCategory(bmi).text(14, 16, 400).c(context.colors.errorBase),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ColorIndicatorBar(bmi: bmi),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoBox("Progress", "2 kg", context),
                SizedBox(width: 16),
                _infoBox(
                  Strings.remained,
                  (weight - targetWeight).abs().toString() + ' kg',
                  context,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearPercentIndicator(
                    animation: true,
                    lineHeight: 16,
                    percent: calculateWeightProgress(weight, targetWeight),
                    backgroundColor: context.colors.backgroundElevation,
                    progressColor: context.colors.accentSub,
                    barRadius: Radius.circular(12),
                    padding: EdgeInsets.all(0),
                  ),
                ),
                SizedBox(width: 4),
                Assets.icons.flag.svg(),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                weight.toString().text(12, 14, 400).c(context.colors.neutral900Primary),
                targetWeight.toString().text(12, 14, 400).c(context.colors.neutral900Primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String title, String value, BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.colors.commonBackground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.text(16, 20, 500).c(context.colors.accentSub),
            const SizedBox(height: 4),
            value.text(16, 20, 500).c(context.colors.textStrong),
          ],
        ),
      ),
    );
  }

  String getBmiCategory(double bmi) {
    if (bmi < 18.5) return Strings.thinnes;
    if (bmi < 25.0) return Strings.normal;
    if (bmi < 30.0) return Strings.overWeight;
    if (bmi < 35.0) return Strings.obesityStage1;
    if (bmi < 40.0) return Strings.obesityStage2;
    return Strings.obesityStage3;
  }

  double calculateWeightProgress(double weight, double targetWeight) {
    if (weight == 0 || targetWeight == 0) return 0.0;
    double progress;
    if (targetWeight < weight) {
      progress = (weight - (weight - targetWeight).abs()) / weight;
    } else {
      progress = weight / targetWeight;
    }
    return progress.clamp(0.0, 1.0);
  }

  String formatBmi(double? bmi) {
    if (bmi == null) return '-';
    if (bmi % 1 == 0) {
      return bmi.toInt().toString();
    } else {
      return bmi.toStringAsFixed(1);
    }
  }
}
