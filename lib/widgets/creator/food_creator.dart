import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class FoodCreatorWidget extends StatefulWidget {
  final void Function(String name, int calories, double protein, double fat, double carbs) onSubmit;

  const FoodCreatorWidget({super.key, required this.onSubmit});

  @override
  State<FoodCreatorWidget> createState() => _FoodCreatorWidgetState();
}

class _FoodCreatorWidgetState extends State<FoodCreatorWidget> {
  final _nameController = TextEditingController();
  final _calorieController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    widget.onSubmit(
      _nameController.text.trim(),
      int.tryParse(_calorieController.text) ?? 0,
      double.tryParse(_proteinController.text) ?? 0,
      double.tryParse(_fatController.text) ?? 0,
      double.tryParse(_carbController.text) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    .auto(minSize: 18),
              ),
              Assets.icons.icCreator.svg(),
            ],
          ),
          CommonTextField(controller: _nameController, hint: Strings.nameOfTheDish),
          CommonTextField(
            controller: _calorieController,
            hint: Strings.calorieContentKcal,
            keyboardType: TextInputType.number,
          ),
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: CommonTextField(
                  controller: _proteinController,
                  hint: Strings.proteinGr,
                  keyboardType: TextInputType.number,
                ),
              ),
              Expanded(
                child: CommonTextField(
                  controller: _fatController,
                  hint: Strings.oilGr,
                  keyboardType: TextInputType.number,
                ),
              ),
              Expanded(
                child: CommonTextField(
                  controller: _carbController,
                  hint: Strings.carbohydrateGr,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Button(text: Strings.add, onPressed: _onAddPressed),
          ),
        ],
      ),
    );
  }
}
