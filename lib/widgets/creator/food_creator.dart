import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart' show Assets;
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                child: Strings.makeYourOwnFood
                    .text(20, 24, 700)
                    .c(context.colors.textStrong)
                    .auto(maxLines: 1, minSize: 18),
              ),
              Assets.icons.icCreator.svg(),
            ],
          ),
          buildSearchField(context: context, onChanged: (value) {}, hint: Strings.nameOfTheDish),
          buildSearchField(context: context, onChanged: (value) {}, hint: Strings.calorieContentKcal),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 16,
            children: [
              Expanded(
                child: buildSearchField(context: context, onChanged: (value) {}, hint: Strings.proteinGr),
              ),
              Expanded(
                child: buildSearchField(context: context, onChanged: (value) {}, hint: Strings.whiteOilGr),
              ),
              Expanded(
                child: buildSearchField(context: context, onChanged: (value) {}, hint: Strings.carbohydrateGr),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Button(onPressed: () {}, text: Strings.creation),
          ),
        ],
      ),
    );
  }

  Widget buildSearchField({
    required BuildContext context,
    required ValueChanged<String> onChanged,
    required String hint,
  }) {
    return TextField(
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.colors.textSub, fontSize: 16, fontWeight: FontWeight.w400, height: 0.8),
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
    );
  }
}
