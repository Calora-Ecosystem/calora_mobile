import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart' show Assets;
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class FoodCreatorWidget extends StatelessWidget {
  const FoodCreatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      child: Column(
        spacing: 16,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Strings.addYourOwnFood
                    .text(20, 24, 700)
                    .c(context.colors.textStrong)
                    .auto(maxLines: 1, minSize: 18),
              ),
              Assets.icons.icCreator.svg(),
            ],
          ),
          CommonTextField(onChanged: (value) {}, hint: Strings.nameOfTheDish),
          CommonTextField(onChanged: (value) {}, hint: Strings.calorieContentKcal),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 16,
            children: [
              Expanded(
                child: CommonTextField(onChanged: (value) {}, hint: Strings.proteinGr),
              ),
              Expanded(
                child: CommonTextField(onChanged: (value) {}, hint: Strings.oilGr),
              ),
              Expanded(
                child: CommonTextField(onChanged: (value) {}, hint: Strings.carbohydrateGr),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Button(onPressed: () {}, text: Strings.add),
          ),
        ],
      ),
    );
  }
}
