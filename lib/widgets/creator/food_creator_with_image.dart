import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class FoodCreatorWithImage extends StatelessWidget {
  final double protein;
  final double oil;
  final double carbohydrates;
  final double calories;
  final String name;
  final VoidCallback addButton;

  const FoodCreatorWithImage({
    super.key,
    required this.name,
    required this.addButton,
    required this.protein,
    required this.oil,
    required this.carbohydrates,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Strings.theValueOfTheFoodDetermined.text(20, 24, 700).c(context.colors.textStrong),
          CommonTextField(
            hint: Strings.nameOfTheDish,
            controller: TextEditingController(text: name),
          ),
          Strings.nutritionalValueOfFood.text(16, 20, 500).c(context.colors.textStrong),
          buildContainer(context: context, value: calories, metric: Strings.kcal),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: buildContainer(context: context, value: protein, metric: 'gr ${Strings.protein}'),
              ),
              Expanded(
                child: buildContainer(context: context, value: oil, metric: 'gr ${Strings.oil}'),
              ),
              Expanded(
                child: buildContainer(context: context, value: calories, metric: 'gr ${Strings.carbohydrate}'),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Button(
              onPressed: () {
                addButton();
                context.router.pop();
              },
              text: Strings.add,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Button(
              type: ButtonType.secondary,
              enabled: false,
              onPressed: () => context.router.pop(),
              text: Strings.cancel,
              textColor: context.colors.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContainer({required BuildContext context, required double value, required String metric}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      decoration: BoxDecoration(color: context.colors.blackWithOpacity, borderRadius: BorderRadius.circular(12)),
      child: '${value.asFixedTruncated(1)}$metric'
          .text(14, 16, 400)
          .c(context.colors.textStrong)
          .copyWith(textAlign: TextAlign.center),
    );
  }
}
