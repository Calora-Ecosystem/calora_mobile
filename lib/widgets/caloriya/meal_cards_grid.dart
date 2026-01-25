import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class MealCardsGrid extends StatelessWidget {
  final List<MealInfo> meals;
  final bool isLoading;

  const MealCardsGrid({
    super.key,
    required this.meals,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = isLoading ? 4 : meals.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final meal = !isLoading
            ? meals[index]
            : MealInfo(
                title: 'title',
                value: 'value',
                max: '100',
                image: SizedBox(),
                onTap: null,
              );
        return ShimmerWrapper(
          loading: isLoading,
          type: ShimmerType.backgroundElevation,
          shimmerChild: const ShimmerChild(height: 120, radius: 12),
          child: isLoading
              ? const SizedBox(height: 120)
              : _mealCard(
                  context,
                  title: meal.title,
                  value: meal.value,
                  max: meal.max,
                  image: meal.image,
                  onTap: meal.onTap ?? () {},
                ),
        );
      },
    );
  }

  Widget _mealCard(
    BuildContext context, {
    required String title,
    required String value,
    required String max,
    required Widget image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
        decoration: BoxDecoration(
          color: context.colors.backgroundElevation,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: -10,
              right: 0,
              child: SizedBox(height: 80, width: 80, child: image),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: title
                          .text(14, 16, 400)
                          .c(context.colors.textSub)
                          .auto(minSize: 12),
                    ),
                    Assets.icons.icPlusCircle.svg(),
                    const SizedBox(width: 8),
                  ],
                ),
                const Spacer(),
                '$value ${Strings.kcal}'
                    .text(16, 20, 500)
                    .c(Colors.black)
                    .auto(minSize: 12),
                const SizedBox(height: 4),
                '$max ${Strings.fromKcal}'.text(14, 16, 600).c(Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
