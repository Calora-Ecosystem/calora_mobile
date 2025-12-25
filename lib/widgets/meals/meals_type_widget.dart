import 'package:cached_network_image/cached_network_image.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class MealTypeGrid extends StatelessWidget {
  final List<MealTypeData> mealTypes;
  final Function(MealTypeData meal) onMealTypeSelected;

  const MealTypeGrid({super.key, required this.mealTypes, required this.onMealTypeSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.04,
      ),
      itemCount: mealTypes.length,
      itemBuilder: (context, index) {
        final mealType = mealTypes[index];
        return _buildMealTypeCard(context: context, mealType: mealType, onTap: () => onMealTypeSelected(mealType));
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
        decoration: BoxDecoration(
          color: context.colors.backgroundElevation,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: mealType.fullImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Image.network(
                    '$baseUrl$abstractImageUrl',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: mealType.name.text(14, 16, 600).c(context.colors.textStrong),
            ),
          ],
        ),
      ),
    );
  }
}

class FavouriteFoodGrid extends StatelessWidget {
  final List<FoodModel> foods;
  final Function(FoodModel) onFoodSelected;

  const FavouriteFoodGrid({super.key, required this.foods, required this.onFoodSelected});

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return Center(child: 'Sevimli ovqatlar yo‘q'.text(14, 18, 500).c(context.colors.textSub));
    }
    return GridView.builder(
      padding: const EdgeInsets.only(top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.04,
      ),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return GestureDetector(
          onTap: () => onFoodSelected(food),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.backgroundElevation,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: food.fullImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Image.network(
                        '$baseUrl$abstractImageUrl',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: food.name.text(14, 16, 600).c(context.colors.textStrong),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
