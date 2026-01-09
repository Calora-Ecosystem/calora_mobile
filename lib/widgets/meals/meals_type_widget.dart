import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class MealTypeGrid extends StatelessWidget {
  final List<MealTypeData> mealTypes;
  final Function(MealTypeData meal) onMealTypeSelected;
  final bool isLoading;

  const MealTypeGrid({
    super.key,
    required this.mealTypes,
    required this.onMealTypeSelected,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: isLoading ? 4 : mealTypes.length,
      itemBuilder: (context, index) {
        final mealType = isLoading
            ? MealTypeData(name: '', imageUrl: '', id: 1)
            : mealTypes[index];
        return ShimmerWrapper(
          loading: isLoading,
          type: ShimmerType.backgroundElevation,
          shimmerChild: ShimmerChild(height: 152),
          child: _buildMealTypeCard(
            context: context,
            mealType: mealType,
            onTap: () => onMealTypeSelected(mealType),
          ),
        );
      },
    );
  }

  Widget _buildMealTypeCard({
    required BuildContext context,
    required MealTypeData mealType,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 152,
        decoration: BoxDecoration(
          color: context.colors.backgroundElevation,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCachedNetworkImage.banner(
              height: 120,
              radius: 16,
              imageUrl: mealType.imageUrl,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: mealType.name
                  .text(14, 16, 600)
                  .c(context.colors.textStrong),
            ),
          ],
        ),
      ),
    );
  }
}

class FavouriteFoodGrid extends StatelessWidget {
  final List<FoodModel> foods;
  final bool isLoading;
  final Function(FoodModel) onFoodSelected;

  const FavouriteFoodGrid({
    super.key,
    required this.foods,
    required this.onFoodSelected,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return Center(
        child: Strings.mealsAreNotAvailable
            .text(14, 18, 500)
            .c(context.colors.textSub),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.only(top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: isLoading ? 4 : foods.length,
      itemBuilder: (context, index) {
        final food = isLoading
            ? FoodModel(
                name: '',
                coverUrl: '',
                id: 1,
                categoryId: 1,
                metrics: [],
              )
            : foods[index];
        return ShimmerWrapper(
          loading: isLoading,
          type: ShimmerType.backgroundElevation,
          shimmerChild: ShimmerChild(height: 152),
          child: GestureDetector(
            onTap: () => onFoodSelected(food),
            child: Container(
              height: 152,
              decoration: BoxDecoration(
                color: context.colors.backgroundElevation,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CustomCachedNetworkImage.banner(
                      radius: 16,
                      height: 120,
                      imageUrl: food.coverUrl,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: food.name
                        .text(14, 16, 600)
                        .c(context.colors.textStrong)
                        .copyWith(overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
