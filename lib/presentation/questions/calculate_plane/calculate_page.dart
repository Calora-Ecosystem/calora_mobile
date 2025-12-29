import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/number_extension/truncate.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/questions/calculate_plane/management/calculate_management.dart';
import 'package:calora/presentation/questions/calculate_plane/management/calculate_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class CalculatePage extends Managed<CalculateManager, CalculateState, CalculateEffect> {
  const CalculatePage({super.key});

  @override
  void init(BuildContext context, CalculateManager manager) {
    super.init(context, manager);
  }

  @override
  listener(BuildContext context, CalculateManager manager, CalculateEffect effect) {
    effect.when(error: (String message) {}, navigateNext: () => goToNextPage(context));
  }

  @override
  Widget builder(BuildContext context, CalculateManager manager, CalculateState state) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(color: context.colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Strings.yourProgramIsReady.text(16, 20, 500).c(context.colors.textStrong),
                        SizedBox(height: 20),
                        _buildIconTextRow(
                          context,
                          icon: Assets.icons.vegetarianFood.svg(),
                          count: '${state.dailyGoals[0].toDouble().asFixedTruncated(0)} ${Strings.kcal}',
                          title: Strings.mealPlan,
                          subtitle: Strings.dailyGoal,
                        ),
                        SizedBox(height: 20),
                        _buildIconTextRow(
                          context,
                          icon: Assets.icons.workoutSport.svg(),
                          count: '6000 ${Strings.step}',
                          title: Strings.steps,
                          subtitle: Strings.dailyGoal,
                        ),
                        SizedBox(height: 20),
                        _buildIconTextRow(
                          context,
                          icon: Assets.icons.water.svg(),
                          count: '${state.dailyGoals[2]} ml',
                          title: Strings.water,
                          subtitle: Strings.dailyGoal,
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colors.backgroundElevation,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Strings.beforeStartingAnyDiet.text(12, 14, 400).c(context.colors.textStrong),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Button(onPressed: () => goToNextPage(context), text: Strings.start),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconTextRow(
    BuildContext context, {
    required Widget icon,
    required String count,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.accentDisabled),
          child: icon,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title.text(16, 20, 400).c(context.colors.textStrong),
            const SizedBox(height: 8),
            '$subtitle $count'.text(12, 16, 400).c(context.colors.textSub),
          ],
        ),
      ],
    );
  }

  void goToNextPage(BuildContext context) {
    context.router.replaceAll([DashboardRoute()]);
  }
}
