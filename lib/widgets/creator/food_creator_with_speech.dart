import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/creator/food_creator.dart';
import 'package:flutter/material.dart';

/// Mutable holder for an AI-detected food so the user can correct its values
/// before the whole batch is added.
class EditableFood {
  String name;
  int calories;
  double protein;
  double fat;
  double carbs;
  final int categoryId;

  EditableFood({
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.categoryId,
  });
}

class FoodCreatorWithSpeech extends StatefulWidget {
  final List<EditableFood> foods;
  final void Function(List<EditableFood> foods) onAdd;
  final bool isLoading;

  const FoodCreatorWithSpeech({
    super.key,
    required this.foods,
    required this.onAdd,
    required this.isLoading,
  });

  @override
  State<FoodCreatorWithSpeech> createState() => _FoodCreatorWithSpeechState();
}

class _FoodCreatorWithSpeechState extends State<FoodCreatorWithSpeech> {
  late final List<EditableFood> _foods = List.of(widget.foods);

  void _editFood(int index) {
    final food = _foods[index];
    context.showAppBottomSheet(
      child: FoodCreatorWidget(
        title: Strings.theValueOfTheFoodDetermined,
        submitText: Strings.save,
        initialName: food.name,
        initialCalories: food.calories,
        initialProtein: food.protein,
        initialFat: food.fat,
        initialCarbs: food.carbs,
        onSubmit: (name, calories, protein, fat, carbs) {
          setState(() {
            food.name = name.isEmpty ? food.name : name;
            food.calories = calories;
            food.protein = protein;
            food.fat = fat;
            food.carbs = carbs;
          });
          context.router.pop();
        },
      ),
    );
  }

  void _removeFood(int index) => setState(() => _foods.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Strings.meals.text(20, 24, 700).c(context.colors.textStrong),
                  const SizedBox(height: 6),
                  Strings.foodsIdentifiedByVoiceMessage
                      .text(14, 18, 400)
                      .c(context.colors.textSub),
                ],
              ),
            ),
            Expanded(
              child: _foods.isEmpty
                  ? Center(
                      child: Strings.foodsIdentifiedByVoiceMessage
                          .text(14, 18, 400)
                          .c(context.colors.textSub),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _foods.length,
                      itemBuilder: (context, index) => _foodCard(context, index),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: Button(
                      onPressed: () => context.router.pop(),
                      text: Strings.cancel,
                      type: ButtonType.secondary,
                      textColor: context.colors.textStrong,
                    ),
                  ),
                  Expanded(
                    child: Button(
                      loading: widget.isLoading,
                      enabled: _foods.isNotEmpty,
                      onPressed: () => widget.onAdd(_foods),
                      text: Strings.add,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodCard(BuildContext context, int index) {
    final item = _foods[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: item.name
                          .text(15, 20, 600)
                          .c(context.colors.textStrong)
                          .auto(minSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.accentGreenWhite,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: '${item.calories} ${Strings.kcal}'
                          .text(12, 14, 600)
                          .c(context.colors.accentSub),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _macro(context, Strings.oils, item.fat),
                    const SizedBox(width: 8),
                    _macro(context, Strings.proteins, item.protein),
                    const SizedBox(width: 8),
                    _macro(context, Strings.carbohydrates, item.carbs),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              _circleBtn(
                context,
                icon: Icons.edit_outlined,
                color: context.colors.textSub,
                background: context.colors.white,
                onTap: () => _editFood(index),
              ),
              const SizedBox(height: 8),
              _circleBtn(
                context,
                icon: Icons.close_rounded,
                color: context.colors.errorBase,
                background: context.colors.errorLighter,
                onTap: () => _removeFood(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macro(BuildContext context, String label, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label.text(10, 12, 500).c(context.colors.textSub).auto(minSize: 8),
            const SizedBox(height: 4),
            value
                .asFixedTruncated(0)
                .text(14, 16, 700)
                .c(context.colors.textStrong)
                .auto(minSize: 11),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
