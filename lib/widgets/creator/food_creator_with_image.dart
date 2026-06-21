import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/text_field/common_text_field.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class FoodCreatorWithImage extends StatefulWidget {
  final double protein;
  final double oil;
  final double carbohydrates;
  final double calories;
  final String name;

  /// Returns the (possibly edited) values so the AI result can be corrected
  /// before it is added to the menu.
  final void Function(
    String name,
    int calories,
    double protein,
    double oil,
    double carbs,
  )
  onAdd;
  final bool isLoading;

  const FoodCreatorWithImage({
    super.key,
    required this.name,
    required this.onAdd,
    required this.protein,
    required this.oil,
    required this.carbohydrates,
    required this.calories,
    required this.isLoading,
  });

  @override
  State<FoodCreatorWithImage> createState() => _FoodCreatorWithImageState();
}

class _FoodCreatorWithImageState extends State<FoodCreatorWithImage> {
  late final _nameController = TextEditingController(text: widget.name);
  late final _calorieController =
      TextEditingController(text: _initText(widget.calories));
  late final _proteinController =
      TextEditingController(text: _initText(widget.protein));
  late final _oilController = TextEditingController(text: _initText(widget.oil));
  late final _carbController =
      TextEditingController(text: _initText(widget.carbohydrates));

  String _initText(double value) =>
      value == 0 ? '' : value.asFixedTruncated(0);

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    _proteinController.dispose();
    _oilController.dispose();
    _carbController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    widget.onAdd(
      _nameController.text.trim(),
      int.tryParse(_calorieController.text) ?? 0,
      double.tryParse(_proteinController.text) ?? 0,
      double.tryParse(_oilController.text) ?? 0,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Strings.theValueOfTheFoodDetermined
              .text(20, 24, 700)
              .c(context.colors.textStrong),
          _labeledField(
            context,
            label: Strings.nameOfTheDish,
            child: CommonTextField(
              hint: '',
              controller: _nameController,
            ),
          ),
          Strings.nutritionalValueOfFood
              .text(16, 20, 500)
              .c(context.colors.textStrong),
          _labeledField(
            context,
            label: Strings.calorieContentKcal,
            child: CommonTextField(
              hint: '',
              controller: _calorieController,
              keyboardType: TextInputType.number,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: _labeledField(
                  context,
                  label: Strings.proteinGr,
                  child: CommonTextField(
                    hint: '',
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              Expanded(
                child: _labeledField(
                  context,
                  label: Strings.oilGr,
                  child: CommonTextField(
                    hint: '',
                    controller: _oilController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              Expanded(
                child: _labeledField(
                  context,
                  label: Strings.carbohydrateGr,
                  child: CommonTextField(
                    hint: '',
                    controller: _carbController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Button(
              loading: widget.isLoading,
              onPressed: _onAddPressed,
              text: Strings.add,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Button(
              type: ButtonType.secondary,
              onPressed: () => context.router.pop(),
              text: Strings.cancel,
              textColor: context.colors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
