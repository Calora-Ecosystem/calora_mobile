import 'package:auto_route/annotations.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/profile/features/norms_page/management/norms_manager.dart';
import 'package:calora/widgets/app_bar/custom_app_bar.dart';
import 'package:calora/widgets/input_bottom_sheet/input_bottom_sheet.dart';
import 'package:calora/widgets/norms_list/dailiy_norms_list.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart' show Managed;

import 'management/norms_management.dart';

@RoutePage()
class NormsPage extends Managed<NormsManager, NormsState, NormsEffect> {
  const NormsPage({super.key});

  @override
  void init(BuildContext context, NormsManager manager) {
    manager.getDailyNorms();
    super.init(context, manager);
  }

  @override
  Widget builder(BuildContext context, NormsManager manager, NormsState state) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: CustomAppBar(title: Strings.norms),
      body: Column(
        children: [
          Divider(color: context.colors.strokeSoft, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: DailyNormsList(
              onCaloriesTap: () {
                showInputBottomSheet(
                  context: context,
                  title: Strings.enterYourDailyCalorie,
                  onSave: (value) {
                    manager.updateDailyNorms(calories: double.parse(value));
                  },
                );
              },
              onCarbsTap: () {
                showInputBottomSheet(
                  context: context,
                  title: Strings.enterYourDailyCarbohydrate,
                  onSave: (value) {
                    manager.updateDailyNorms(carbs: double.parse(value));
                  },
                );
              },
              onFatTap: () {
                showInputBottomSheet(
                  context: context,
                  title: Strings.enterYourDailyFat,
                  onSave: (value) {
                    manager.updateDailyNorms(fat: double.parse(value));
                  },
                );
              },
              onProteinTap: () {
                showInputBottomSheet(
                  context: context,
                  title: Strings.enterYourDailyProtein,
                  onSave: (value) {
                    manager.updateDailyNorms(protein: double.parse(value));
                  },
                );
              },
              onStepsTap: () {
                showInputBottomSheet(
                  context: context,
                  title: Strings.enterYourDailyStepGoal,
                  onSave: (value) {
                    manager.updateDailyNorms(steps: double.parse(value));
                  },
                );
              },
              onWaterTap: () {
                showInputBottomSheet(
                  context: context,
                  title: Strings.enterYourDailyWater,
                  onSave: (value) {
                    manager.updateDailyNorms(water: double.parse(value));
                  },
                );
              },
              calories: state.dailyNorms.calories,
              protein: state.dailyNorms.protein,
              fat: state.dailyNorms.fat,
              carbs: state.dailyNorms.carbs,
              water: state.dailyNorms.water,
              steps: state.dailyNorms.steps,
            ),
          ),
        ],
      ),
    );
  }
}
