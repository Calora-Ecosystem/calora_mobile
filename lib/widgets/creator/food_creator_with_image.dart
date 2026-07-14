import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
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

  /// AI-estimated portion weight (grams). Editing it rescales the macros.
  final int weight;

  /// Returns the (possibly edited) values so the AI result can be corrected
  /// before it is added to the menu.
  final void Function(
    String name,
    int calories,
    double protein,
    double oil,
    double carbs,
    int weight,
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
    required this.weight,
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
  late final _weightController =
      TextEditingController(text: widget.weight > 0 ? '${widget.weight}' : '');

  /// Immutable AI baseline. Macros are always rescaled from this so
  /// intermediate keystrokes in the weight field never lose precision.
  late double _baseWeight = widget.weight.toDouble();
  late double _baseCalories = widget.calories;
  late double _baseProtein = widget.protein;
  late double _baseOil = widget.oil;
  late double _baseCarb = widget.carbohydrates;

  String _initText(double value) =>
      value == 0 ? '' : value.asFixedTruncated(0);

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onWeightChanged);
  }

  /// Rescales the macros proportionally to the edited weight. Always scales
  /// from the AI baseline (not the previous field value) so partial input
  /// like 2 → 25 → 250 self-corrects to the exact final ratio.
  void _onWeightChanged() {
    final newWeight = double.tryParse(_weightController.text.trim());
    if (newWeight == null || newWeight <= 0) return;

    if (_baseWeight <= 0) {
      // AI returned no weight — adopt the first entered value as the base
      // without touching the macros the user already sees.
      _baseWeight = newWeight;
      _baseCalories = double.tryParse(_calorieController.text) ?? 0;
      _baseProtein = double.tryParse(_proteinController.text) ?? 0;
      _baseOil = double.tryParse(_oilController.text) ?? 0;
      _baseCarb = double.tryParse(_carbController.text) ?? 0;
      return;
    }

    final factor = newWeight / _baseWeight;
    _setText(_calorieController, (_baseCalories * factor).asFixedTruncated(0));
    _setText(_proteinController, (_baseProtein * factor).asFixedTruncated(0));
    _setText(_oilController, (_baseOil * factor).asFixedTruncated(0));
    _setText(_carbController, (_baseCarb * factor).asFixedTruncated(0));
  }

  void _setText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _weightController.removeListener(_onWeightChanged);
    _nameController.dispose();
    _calorieController.dispose();
    _proteinController.dispose();
    _oilController.dispose();
    _carbController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    final weight = int.tryParse(_weightController.text.trim()) ?? 0;
    widget.onAdd(
      _nameController.text.trim(),
      int.tryParse(_calorieController.text) ?? 0,
      double.tryParse(_proteinController.text) ?? 0,
      double.tryParse(_oilController.text) ?? 0,
      double.tryParse(_carbController.text) ?? 0,
      weight,
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
          _labeledField(
            context,
            label: 'food_amount'.tr(),
            child: CommonTextField(
              hint: Strings.enterTheAmountOfFoodGr,
              controller: _weightController,
              keyboardType: TextInputType.number,
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
