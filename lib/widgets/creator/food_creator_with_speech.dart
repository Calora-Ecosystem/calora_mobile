import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/creator/food_creator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Mutable holder for an AI-detected food so the user can correct its values
/// before the whole batch is added.
class EditableFood {
  String name;
  int calories;
  double protein;
  double fat;
  double carbs;
  final int categoryId;

  /// AI-estimated portion weight (grams); editable so the menu item is logged
  /// against the real weight instead of a fixed 400g.
  int weight;

  EditableFood({
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.categoryId,
    required this.weight,
  });
}

class FoodCreatorWithSpeech extends StatefulWidget {
  final List<EditableFood> foods;
  final void Function(List<EditableFood> foods) onAdd;
  final bool isLoading;

  /// Local path of the captured photo when this batch came from a food scan.
  /// Null for the voice flow, where no photo exists.
  final String? imagePath;

  /// Sheet header. Defaults keep the original voice-flow copy so existing
  /// callers are unaffected; the scan flow passes photo-appropriate text.
  final String? title;
  final String? subtitle;

  const FoodCreatorWithSpeech({
    super.key,
    required this.foods,
    required this.onAdd,
    required this.isLoading,
    this.imagePath,
    this.title,
    this.subtitle,
  });

  @override
  State<FoodCreatorWithSpeech> createState() => _FoodCreatorWithSpeechState();
}

class _FoodCreatorWithSpeechState extends State<FoodCreatorWithSpeech> {
  late final List<EditableFood> _foods = List.of(widget.foods);

  void _editFood(int index) {
    final food = _foods[index];
    context.showAppBottomSheet(
      child: FoodCreatorWidget(
        title: Strings.theValueOfTheFoodDetermined,
        submitText: Strings.save,
        initialName: food.name,
        initialCalories: food.calories,
        initialProtein: food.protein,
        initialFat: food.fat,
        initialCarbs: food.carbs,
        initialWeight: food.weight,
        onSubmit: (name, calories, protein, fat, carbs, weight) {
          setState(() {
            food.name = name.isEmpty ? food.name : name;
            food.calories = calories;
            food.protein = protein;
            food.fat = fat;
            food.carbs = carbs;
            food.weight = weight;
          });
          context.router.pop();
        },
      ),
    );
  }

  void _removeFood(int index) => setState(() => _foods.removeAt(index));

  /// Subtitle that matches the source of the batch: an explicit override, a
  /// photo-scan message when a captured photo is present, or the voice-flow
  /// default otherwise.
  String _resolvedSubtitle(BuildContext context) {
    if (widget.subtitle != null) return widget.subtitle!;
    if (widget.imagePath != null) {
      switch (context.locale.languageCode) {
        case 'ru':
          return 'Продукты, распознанные по фото';
        case 'en':
          return 'Foods detected from the photo';
        case 'uz':
        default:
          return 'Rasm orqali aniqlangan ovqatlar';
      }
    }
    return Strings.foodsIdentifiedByVoiceMessage;
  }

  /// Localized "total weight" label. Inlined (rather than a generated string)
  /// to match the existing locale-switch pattern used elsewhere in the app.
  String _weightLabel(BuildContext context) {
    switch (context.locale.languageCode) {
      case 'ru':
        return 'Общий вес';
      case 'en':
        return 'Total weight';
      case 'uz':
      default:
        return 'Umumiy vazn';
    }
  }

  // ── Live totals across all (still-listed, possibly edited) foods ──────
  int get _totalKcal => _foods.fold(0, (s, f) => s + f.calories);
  double get _totalProtein => _foods.fold(0.0, (s, f) => s + f.protein);
  double get _totalFat => _foods.fold(0.0, (s, f) => s + f.fat);
  double get _totalCarbs => _foods.fold(0.0, (s, f) => s + f.carbs);
  int get _totalWeight => _foods.fold(0, (s, f) => s + f.weight);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (widget.title ?? Strings.meals)
                      .text(20, 24, 700)
                      .c(context.colors.textStrong),
                  const SizedBox(height: 6),
                  _resolvedSubtitle(context)
                      .text(14, 18, 400)
                      .c(context.colors.textSub),
                ],
              ),
            ),
            Expanded(
              child: _foods.isEmpty
                  ? Center(
                      child: Strings.foodsIdentifiedByVoiceMessage
                          .text(14, 18, 400)
                          .c(context.colors.textSub),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        _summaryCard(context),
                        const SizedBox(height: 16),
                        Strings.meals
                            .text(16, 20, 600)
                            .c(context.colors.textStrong),
                        const SizedBox(height: 8),
                        ...List.generate(
                          _foods.length,
                          (index) => _foodCard(context, index),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: Button(
                      onPressed: () => context.router.pop(),
                      text: Strings.cancel,
                      type: ButtonType.secondary,
                      textColor: context.colors.textStrong,
                    ),
                  ),
                  Expanded(
                    child: Button(
                      loading: widget.isLoading,
                      enabled: _foods.isNotEmpty,
                      onPressed: () => widget.onAdd(_foods),
                      text: Strings.add,
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

  /// Hero summary: dish photo on the left, the combined nutrition of every
  /// detected food on the right (total kcal + protein/fat/carb + weight).
  Widget _summaryCard(BuildContext context) {
    final path = widget.imagePath;
    final hasPhoto =
        path != null && path.isNotEmpty && File(path).existsSync();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(path),
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoFallback(context),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        '$_totalKcal'
                            .text(28, 32, 700)
                            .c(context.colors.textStrong),
                        const SizedBox(width: 4),
                        Strings.kcal.text(14, 18, 500).c(context.colors.textSub),
                      ],
                    ),
                    if (_totalWeight > 0) ...[
                      const SizedBox(height: 2),
                      '${_weightLabel(context)}: $_totalWeight gr'
                          .text(12, 16, 400)
                          .c(context.colors.textSub),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _summaryMacro(context, Strings.proteins, _totalProtein),
                        const SizedBox(width: 8),
                        _summaryMacro(context, Strings.oils, _totalFat),
                        const SizedBox(width: 8),
                        _summaryMacro(context, Strings.carbohydrates, _totalCarbs),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoFallback(BuildContext context) => Container(
        width: 96,
        height: 96,
        color: context.colors.white,
        alignment: Alignment.center,
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: context.colors.textSub,
        ),
      );

  Widget _summaryMacro(BuildContext context, String label, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label.text(10, 12, 500).c(context.colors.textSub).auto(minSize: 8),
            const SizedBox(height: 4),
            '${value.asFixedTruncated(0)} gr'
                .text(14, 16, 700)
                .c(context.colors.textStrong)
                .auto(minSize: 11),
          ],
        ),
      ),
    );
  }

  Widget _foodCard(BuildContext context, int index) {
    final item = _foods[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.backgroundElevation,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: item.name
                          .text(15, 20, 600)
                          .c(context.colors.textStrong)
                          .auto(minSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.accentGreenWhite,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: '${item.calories} ${Strings.kcal}'
                          .text(12, 14, 600)
                          .c(context.colors.accentSub),
                    ),
                  ],
                ),
                if (item.weight > 0) ...[
                  const SizedBox(height: 4),
                  '${item.weight} gr'
                      .text(12, 16, 500)
                      .c(context.colors.textSub),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _macro(context, Strings.oils, item.fat),
                    const SizedBox(width: 8),
                    _macro(context, Strings.proteins, item.protein),
                    const SizedBox(width: 8),
                    _macro(context, Strings.carbohydrates, item.carbs),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              _circleBtn(
                context,
                icon: Icons.edit_outlined,
                color: context.colors.textSub,
                background: context.colors.white,
                onTap: () => _editFood(index),
              ),
              const SizedBox(height: 8),
              _circleBtn(
                context,
                icon: Icons.close_rounded,
                color: context.colors.errorBase,
                background: context.colors.errorLighter,
                onTap: () => _removeFood(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macro(BuildContext context, String label, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label.text(10, 12, 500).c(context.colors.textSub).auto(minSize: 8),
            const SizedBox(height: 4),
            value
                .asFixedTruncated(0)
                .text(14, 16, 700)
                .c(context.colors.textStrong)
                .auto(minSize: 11),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
