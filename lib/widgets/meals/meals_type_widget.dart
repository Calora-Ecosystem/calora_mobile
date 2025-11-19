import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class MealTypeGrid extends StatelessWidget {
  final List<MealTypeData> mealTypes;
  final Function(MealCategory) onMealTypeSelected;

  const MealTypeGrid({Key? key, required this.mealTypes, required this.onMealTypeSelected}) : super(key: key);

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
        return _buildMealTypeCard(context: context, mealType: mealType, onTap: () => onMealTypeSelected(mealType.type));
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
        decoration: BoxDecoration(color: context.colors.backgroundElevation, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: mealType.image),
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
