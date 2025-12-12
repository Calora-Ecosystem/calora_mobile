import 'package:calora/common/extensions/foods_extension.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/domain/model/meal/food/food_models.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/carousel/food_carousel.dart';
import 'package:calora/widgets/steper/food_stepper.dart';
import 'package:flutter/material.dart' hide StepperType;
import 'package:flutter/services.dart';

class DishInfoPage extends StatefulWidget {
  final FoodItem foodItem;

  const DishInfoPage({super.key, required this.foodItem});

  @override
  State<DishInfoPage> createState() => _DishInfoPageState();
}

class _DishInfoPageState extends State<DishInfoPage> {
  bool isFavourite = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        child: Column(
          spacing: 8,
          children: [
            SizedBox(height: 4),
            FoodCarousel(),
            SizedBox(height: 8),
            FoodStepper(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.foodItem.name.text(24, 32, 700).c(context.colors.textStrong),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isFavourite = !isFavourite;
                          });
                        },
                        child: isFavourite ? Assets.icons.icRedFavourite.svg() : Assets.icons.icFavourite.svg(),
                      ),
                    ],
                  ),
                  '400 grammdagi ozuqaviyligi'.text(16, 20, 400).c(context.colors.textSub),
                  Row(
                    children: [
                      buildNutritionItem(
                        padding: EdgeInsets.fromLTRB(0, 8, 12, 8),
                        borderColor: Colors.transparent,
                        value: widget.foodItem.proteins, // ✅
                        label: Strings.proteins,
                      ),
                      buildNutritionItem(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        borderColor: context.colors.strokeSoft,
                        value: widget.foodItem.carbohydrates, // ✅
                        label: Strings.carbohydrates,
                      ),
                      buildNutritionItem(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        borderColor: context.colors.strokeSoft,
                        value: widget.foodItem.fats, // ✅
                        label: Strings.oils,
                      ),
                    ],
                  ),
                  widget.foodItem.description.text(14, 16, 400).c(context.colors.textSub),
                  GestureDetector(
                    onTap: () {},
                    child: Strings.moreDetails.text(14, 16, 600).c(context.colors.accentSub),
                  ),
                  Strings.addASpecificAmount.text(14, 16, 600).c(context.colors.textStrong),
                  TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: Strings.enterTheAmountOfFoodGr,
                      hintStyle: TextStyle(
                        color: context.colors.textSub,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 0.8,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.colors.strokeSoft, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.colors.blue, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Button(onPressed: () {}, text: Strings.save),
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
          border: Border(left: BorderSide(color: borderColor, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            "${value.asFixedTruncated(1)} gr".toString().text(16, 20, 500),
            label.text(14, 18, 400).c(context.colors.textSub),
          ],
        ),
      ),
    );
  }
}
