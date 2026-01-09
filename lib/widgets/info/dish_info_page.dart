import 'package:calora/common/extensions/foods_extension.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart' hide StepperType;
import 'package:flutter/services.dart';

class DishInfoPage extends StatefulWidget {
  final FoodModel foodItem;
  final ValueChanged<double> onSave;
  final bool isFavourite;
  final ValueChanged<bool> onFavouriteChanged;

  const DishInfoPage({
    super.key,
    required this.foodItem,
    required this.onSave,
    required this.isFavourite,
    required this.onFavouriteChanged,
  });

  @override
  State<DishInfoPage> createState() => _DishInfoPageState();
}

class _DishInfoPageState extends State<DishInfoPage> {
  bool isFavourite = false;

  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isFavourite = widget.isFavourite;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          spacing: 8,
          children: [
            SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomCachedNetworkImage.banner(
                imageUrl: widget.foodItem.coverUrl,
                height: 160,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.foodItem.name
                          .text(24, 32, 700)
                          .c(context.colors.textStrong),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isFavourite = !isFavourite;
                          });
                          widget.onFavouriteChanged(isFavourite);
                        },
                        child: isFavourite
                            ? Assets.icons.icRedFavourite.svg()
                            : Assets.icons.icFavourite.svg(),
                      ),
                    ],
                  ),
                  '400 grammdagi ozuqaviyligi'
                      .text(16, 20, 400)
                      .c(context.colors.textSub),
                  Row(
                    children: [
                      buildNutritionItem(
                        padding: EdgeInsets.fromLTRB(0, 8, 12, 8),
                        borderColor: Colors.transparent,
                        value: widget.foodItem.cal,
                        label: Strings.calories,
                      ),
                      buildNutritionItem(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        borderColor: context.colors.strokeSoft,
                        value: widget.foodItem.proteins,
                        label: Strings.proteins,
                      ),
                      buildNutritionItem(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        borderColor: context.colors.strokeSoft,
                        value: widget.foodItem.carbohydrates,
                        label: Strings.carbohydrates,
                      ),
                      buildNutritionItem(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        borderColor: context.colors.strokeSoft,
                        value: widget.foodItem.fats,
                        label: Strings.oils,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Strings.moreDetails
                        .text(14, 16, 600)
                        .c(context.colors.accentSub),
                  ),
                  Strings.addASpecificAmount
                      .text(14, 16, 600)
                      .c(context.colors.textStrong),
                  CommonTextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    hint: Strings.enterTheAmountOfFoodGr,
                    controller: _amountController,
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Button(
                      onPressed: () {
                        final text = _amountController.text.trim();
                        double? amount = double.tryParse(text);
                        if (text.isEmpty || amount == null || amount <= 0) {
                          amount = widget.foodItem.weight;
                        }
                        widget.onSave(amount);
                      },
                      text: Strings.save,
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

  Widget buildNutritionItem({
    required double value,
    required String label,
    required EdgeInsets padding,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            '${value.asFixedTruncated(0)} gr'.toString().text(16, 20, 500),
            label
                .text(14, 18, 400)
                .c(context.colors.textSub)
                .copyWith(maxLines: 1),
          ],
        ),
      ),
    );
  }
}
