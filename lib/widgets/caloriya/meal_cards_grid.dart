import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class MealInfo {
  final String title;
  final String value;
  final String max;
  final Widget image;
  final VoidCallback? onTap;

  MealInfo({required this.title, required this.value, required this.max, required this.image, required this.onTap});
}

class MealCardsGrid extends StatelessWidget {
  final List<MealInfo> meals;
  final bool loading;

  const MealCardsGrid({super.key, required this.meals, required this.loading});

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
        return ShimmerWrapper(
          loading: loading,
          type: ShimmerType.backgroundElevation,
          radius: 12,
          shimmerChild: _shimmerCard(context),
          child: _mealCard(
            context,
            title: meal.title,
            value: meal.value,
            max: meal.max,
            image: meal.image,
            onTap: meal.onTap ?? () {},
          ),
        );
      }).toList(),
    );
  }

  Widget _shimmerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(12),
      ),
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
                    Expanded(child: title.text(14, 16, 400).c(context.colors.textSub).auto(minSize: 12)),
                    Assets.icons.icPlusCircle.svg(),
                    const SizedBox(width: 8),
                  ],
                ),
                const Spacer(),
                '$value kkal'.text(16, 20, 500).c(Colors.black).auto(minSize: 12),
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
