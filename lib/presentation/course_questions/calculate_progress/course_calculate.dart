import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CourseCalculate extends StatelessWidget {
  const CourseCalculate({
    super.key,
    this.onStart,
    this.calories = 1800,
    this.steps = 6000,
    this.waterMl = 2000,
  });

  final VoidCallback? onStart;

  final num calories;
  final int steps;
  final int waterMl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.fill),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Strings.yourProgramIsReady.text(16, 20, 500).c(context.colors.textStrong),
                        const SizedBox(height: 20),

                        _buildIconTextRow(
                          context,
                          icon: Assets.icons.vegetarianFood.svg(),
                          count: '${calories.toDouble().asFixedTruncated(0)} ${Strings.kcal}',
                          title: Strings.mealPlan,
                          subtitle: Strings.dailyGoal,
                        ),
                        const SizedBox(height: 20),

                        _buildIconTextRow(
                          context,
                          icon: Assets.icons.workoutSport.svg(),
                          count: '$steps ${Strings.step}',
                          title: Strings.steps,
                          subtitle: Strings.dailyGoal,
                        ),
                        const SizedBox(height: 20),

                        _buildIconTextRow(
                          context,
                          icon: Assets.icons.water.svg(),
                          count: '$waterMl ml',
                          title: Strings.water,
                          subtitle: Strings.dailyGoal,
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colors.backgroundElevation,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Strings.beforeStartingAnyDiet.text(12, 14, 400).c(context.colors.textStrong),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Button(
                      onPressed: onStart,
                      text: Strings.start,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconTextRow(
    BuildContext context, {
    required Widget icon,
    required String count,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.accentDisabled,
          ),
          child: icon,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.text(16, 20, 400).c(context.colors.textStrong),
            const SizedBox(height: 8),
            '$subtitle $count'.text(12, 16, 400).c(context.colors.textSub),
          ],
        ),
      ],
    );
  }
}
