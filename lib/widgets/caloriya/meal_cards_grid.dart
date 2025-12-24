import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class MealCardsGrid extends StatelessWidget {
  final List<MealInfo> meals;

  const MealCardsGrid({super.key, required this.meals});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: meals.map((meal) {
        return _mealCard(
          context,
          title: meal.title,
          value: meal.value,
          max: meal.max,
          image: meal.image,
          onTap: meal.onTap ?? () {},
        );
      }).toList(),
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
        padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
        decoration: BoxDecoration(color: context.colors.backgroundElevation, borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Positioned(bottom: -10, right: 0, child: SizedBox(height: 80, width: 80, child: image)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: title.text(14, 16, 400).c(context.colors.textSub).auto(maxLines: 1, minSize: 12)),
                    Assets.icons.icPlusCircle.svg(),
                    const SizedBox(width: 8),
                  ],
                ),
                const Spacer(),
                '$value kkal'.text(16, 20, 500).c(Colors.black).auto(maxLines: 1, minSize: 12),
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
