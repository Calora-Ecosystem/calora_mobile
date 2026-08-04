import 'package:easy_localization/easy_localization.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
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
    int weight,
  )
  onSubmit;

  /// When provided, the form is prefilled for editing an existing food.
  final String? initialName;
  final int? initialCalories;
  final double? initialProtein;
  final double? initialFat;
  final double? initialCarbs;

  /// Portion weight (grams). Editing it rescales the macros proportionally.
  /// `null`/`0` hides the field (e.g. manual "add your own food").
  final int? initialWeight;

  /// Optional overrides for the header title and submit button label.
  final String? title;
  final String? submitText;

  /// Cover photo (relative `coverUrl`) of the food being edited. Shown as a
  /// banner at the top so the dish — including a user's scanned photo — is
  /// visible while editing. Null/empty hides it (e.g. "add your own food").
  final String? imageUrl;

  const FoodCreatorWidget({
    super.key,
    required this.onSubmit,
    this.initialName,
    this.initialCalories,
    this.initialProtein,
    this.initialFat,
    this.initialCarbs,
    this.initialWeight,
    this.title,
    this.submitText,
    this.imageUrl,
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
  late final _weightController = TextEditingController(
    text: (widget.initialWeight ?? 0) > 0 ? '${widget.initialWeight}' : '',
  );

  /// Whether the portion-weight field is shown (AI-scan flow only).
  bool get _hasWeight => widget.initialWeight != null;

  /// Immutable baseline used to rescale macros from the weight field without
  /// compounding rounding errors across keystrokes.
  late double _baseWeight = (widget.initialWeight ?? 0).toDouble();
  late double _baseCalories = (widget.initialCalories ?? 0).toDouble();
  late double _baseProtein = widget.initialProtein ?? 0;
  late double _baseFat = widget.initialFat ?? 0;
  late double _baseCarb = widget.initialCarbs ?? 0;

  String? _initText(num? value) {
    if (value == null || value == 0) return null;
    return value is int ? value.toString() : value.toStringAsFixed(0);
  }

  @override
  void initState() {
    super.initState();
    if (_hasWeight) _weightController.addListener(_onWeightChanged);
  }

  void _onWeightChanged() {
    final newWeight = double.tryParse(_weightController.text.trim());
    if (newWeight == null || newWeight <= 0) return;

    if (_baseWeight <= 0) {
      _baseWeight = newWeight;
      _baseCalories = double.tryParse(_calorieController.text) ?? 0;
      _baseProtein = double.tryParse(_proteinController.text) ?? 0;
      _baseFat = double.tryParse(_fatController.text) ?? 0;
      _baseCarb = double.tryParse(_carbController.text) ?? 0;
      return;
    }

    final factor = newWeight / _baseWeight;
    _setText(_calorieController, (_baseCalories * factor).toStringAsFixed(0));
    _setText(_proteinController, (_baseProtein * factor).toStringAsFixed(0));
    _setText(_fatController, (_baseFat * factor).toStringAsFixed(0));
    _setText(_carbController, (_baseCarb * factor).toStringAsFixed(0));
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
    _fatController.dispose();
    _carbController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    widget.onSubmit(
      _nameController.text.trim(),
      int.tryParse(_calorieController.text) ?? 0,
      double.tryParse(_proteinController.text) ?? 0,
      double.tryParse(_fatController.text) ?? 0,
      double.tryParse(_carbController.text) ?? 0,
      int.tryParse(_weightController.text.trim()) ?? 0,
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
          if ((widget.imageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomCachedNetworkImage.banner(
                imageUrl: widget.imageUrl,
                width: double.infinity,
                height: 150,
              ),
            ),
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
          if (_hasWeight)
            _labeledField(
              context,
              label: 'food_amount'.tr(),
              child: CommonTextField(
                controller: _weightController,
                hint: Strings.enterTheAmountOfFoodGr,
                keyboardType: TextInputType.number,
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
