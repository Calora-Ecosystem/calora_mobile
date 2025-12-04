import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class DailyPlanWidget extends StatelessWidget {
  final VoidCallback onBackward;
  final VoidCallback onForward;
  final String day;
  final String month;
  final String calories;
  final String water;
  final String steps;

  const DailyPlanWidget({
    super.key,
    required this.onBackward,
    required this.onForward,
    required this.day,
    required this.month,
    required this.calories,
    required this.water,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.accentSub,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onBackward,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Assets.icons.icBackward.svg(),
                  ),
                ),
                Column(
                  children: [
                    'Bugun'.text(14, 16, 400).c(context.colors.white),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        day.text(14, 16, 400).c(context.colors.textWhite),
                        const SizedBox(width: 4),
                        month.text(14, 16, 400).c(context.colors.white),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: onForward,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Assets.icons.icForward.svg(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Strings.planForToday.text(20, 24, 600),
                const SizedBox(height: 12),
                Row(
                  spacing: 8,
                  children: [
                    _buildCaloriesInfo(
                      context: context,
                      item: calories,
                      icon: Assets.icons.vegetarianFood.svg(),
                    ),
                    _buildCaloriesInfo(
                      context: context,
                      item: water,
                      icon: Assets.icons.droplet.svg(),
                    ),
                    _buildCaloriesInfo(
                      context: context,
                      item: steps,
                      icon: Assets.icons.workoutRun.svg(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesInfo({
    required BuildContext context,
    required String item,
    required Widget icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.backgroundElevation,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            SizedBox(height: 20, width: 20, child: icon),
            const SizedBox(width: 8),
            Expanded(
              child: item
                  .text(14, 16, 400)
                  .c(context.colors.textStrong)
                  .copyWith(overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
