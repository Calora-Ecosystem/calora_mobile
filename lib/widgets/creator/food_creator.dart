import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class FoodCreatorWidget extends StatefulWidget {
  final void Function(
    String name,
    int calories,
    double protein,
    double fat,
    double carbs,
  )
  onSubmit;

  /// When provided, the form is prefilled for editing an existing food.
  final String? initialName;
  final int? initialCalories;
  final double? initialProtein;
  final double? initialFat;
  final double? initialCarbs;

  /// Optional overrides for the header title and submit button label.
  final String? title;
  final String? submitText;

  const FoodCreatorWidget({
    super.key,
    required this.onSubmit,
    this.initialName,
    this.initialCalories,
    this.initialProtein,
    this.initialFat,
    this.initialCarbs,
    this.title,
    this.submitText,
  });

  @override
  State<FoodCreatorWidget> createState() => _FoodCreatorWidgetState();
}

class _FoodCreatorWidgetState extends State<FoodCreatorWidget> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _calorieController =
      TextEditingController(text: _initText(widget.initialCalories));
  late final _proteinController =
      TextEditingController(text: _initText(widget.initialProtein));
  late final _fatController =
      TextEditingController(text: _initText(widget.initialFat));
  late final _carbController =
      TextEditingController(text: _initText(widget.initialCarbs));

  String? _initText(num? value) {
    if (value == null || value == 0) return null;
    return value is int ? value.toString() : value.toStringAsFixed(0);
  }

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

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label.text(13, 16, 500).c(context.colors.textSub),
        const SizedBox(height: 6),
        child,
      ],
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
                child: (widget.title ?? Strings.addYourOwnFood)
                    .text(20, 24, 700)
                    .c(context.colors.textStrong)
                    .auto(minSize: 18),
              ),
              Assets.icons.icCreator.svg(),
            ],
          ),
          _labeledField(
            context,
            label: Strings.nameOfTheDish,
            child: CommonTextField(
              controller: _nameController,
              hint: '',
            ),
          ),
          _labeledField(
            context,
            label: Strings.calorieContentKcal,
            child: CommonTextField(
              controller: _calorieController,
              hint: '',
              keyboardType: TextInputType.number,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Expanded(
                child: _labeledField(
                  context,
                  label: Strings.proteinGr,
                  child: CommonTextField(
                    controller: _proteinController,
                    hint: '',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              Expanded(
                child: _labeledField(
                  context,
                  label: Strings.oilGr,
                  child: CommonTextField(
                    controller: _fatController,
                    hint: '',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              Expanded(
                child: _labeledField(
                  context,
                  label: Strings.carbohydrateGr,
                  child: CommonTextField(
                    controller: _carbController,
                    hint: '',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Button(text: widget.submitText ?? Strings.add, onPressed: _onAddPressed),
          ),
        ],
      ),
    );
  }
}
