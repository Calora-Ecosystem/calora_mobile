import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/meal_type_text_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/domain/model/meal/dish/dish_data.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/info/dish_info_page.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'management/dishes_management.dart';
import 'management/dishes_manager.dart';

@RoutePage()
class DishesPage extends Managed<DishesManager, DishesState, DishesEffect> {
  final MealCategory mealCategory;

  const DishesPage({super.key, required this.mealCategory});

  @override
  void init(BuildContext context, DishesManager manager) {
    super.init(context, manager);

    manager.getDishes(mealCategory);
  }

  @override
  Widget builder(BuildContext context, DishesManager manager, DishesState state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(title: mealCategory.displayName),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: GridView.builder(
          padding: const EdgeInsets.only(top: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.04,
          ),
          itemCount: state.dishes.length,
          itemBuilder: (context, index) {
            final dish = state.dishes[index];
            return GestureDetector(
              onTap: () => openAboutDishPage(context, dish),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.backgroundElevation,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(dish.imageUrl)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: dish.name.text(14, 16, 600).c(context.colors.textStrong),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void openAboutDishPage(BuildContext context, DishData dish) {
    context.showAppBottomSheet(child: DishInfoPage(dish: dish));
  }
}
