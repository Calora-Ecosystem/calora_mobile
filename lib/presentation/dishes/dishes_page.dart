import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/domain/model/calories/calories_data.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/domain/model/meal/meal_type_data.dart';
import 'package:calora/domain/model/meal/menu/menu_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dishes/management/dishes_management.dart';
import 'package:calora/presentation/dishes/management/dishes_manager.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/info/dish_info_page.dart';
import 'package:calora/widgets/meals/paginated_food_grid.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class DishesPage extends Managed<DishesManager, DishesState, DishesEffect> {
  final MealTypeData data;
  final MealType type;
  final List<MealData> meals;
  final DateTime dateTime;
  final int categoryId;

  const DishesPage({
    super.key,
    required this.meals,
    required this.dateTime,
    required this.categoryId,
    required this.type,
    required this.data,
  });

  @override
  void init(BuildContext context, DishesManager manager) {
    super.init(context, manager);
    manager.bindCategory(data.id);
  }

  @override
  void listener(
    BuildContext context,
    DishesManager manager,
    DishesEffect effect,
  ) {
    super.listener(context, manager, effect);
    effect.mapOrNull(
      openInfoSheet: (value) {
        openAboutDishPage(context, value.food, manager, value.isFavourite);
      },
    );
  }

  @override
  Widget builder(
    BuildContext context,
    DishesManager manager,
    DishesState state,
  ) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(title: data.name),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: PaginatedFoodGrid(
          controller: manager.paginator.pagingController,
          onFoodSelected: (food) =>
              manager.getFoodById(food.id!, food.isFavourite),
        ),
      ),
    );
  }

  void openAboutDishPage(
    BuildContext context,
    FoodModel food,
    DishesManager manager,
    bool isFavourite,
  ) {
    context.showAppBottomSheet(
      child: DishInfoPage(
        isFavourite: isFavourite,
        foodItem: food,
        onFavouriteChanged: (value) {
          if (value) manager.addFavourite(food.id ?? 0);
        },
        onSave: (value) async {
          manager.addFavourite(food.id ?? 0);
          final success = await manager.saveMenuItem(
            MenuInfo(
              menu: type.name,
              date: dateTime,
              foodId: food.id ?? 0,
              weightInGr: value == 0 ? 100 : value.toInt(),
            ),
          );
          if (context.mounted) context.router.pop();

          if (success) {
            _showInfoDialog(context);
          }
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.lightGreen,
            ),
            child: Assets.icons.twoDone.svg(),
          ),
          content: Strings.yourDataHasBeenSaved
              .text(16, 20, 400)
              .c(context.colors.textStrong)
              .copyWith(textAlign: TextAlign.center),
          actions: [
            Center(
              child: Button(
                onPressed: () {
                  dialogContext.pop();
                  context.router.pop();
                  context.router.pop(true);
                },
                text: Strings.close,
                textColor: context.colors.textStrong,
                type: ButtonType.secondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
