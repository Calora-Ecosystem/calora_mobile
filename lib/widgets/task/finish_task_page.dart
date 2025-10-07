import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/tasks/management/tasks_management.dart';
import 'package:calora/presentation/tasks/management/tasks_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'mood_selector_widget.dart';

@RoutePage()
class FinishTaskPage extends Managed<TasksManager, TasksState, TasksEffect> {
  final int day;
  final int taskCount;
  final double calories;
  final int duration;
  const FinishTaskPage(this.day, this.taskCount, this.calories, this.duration, {super.key});

  @override
  Widget builder(BuildContext context, TasksManager manager, TasksState state) {
    return Scaffold(
      backgroundColor: context.colors.black,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Assets.images.femaleFinishBackground.image(fit: BoxFit.cover),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: MediaQuery.of(context).size.height * 0.25,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 200, width: 200, child: Assets.images.finishIcon.image()),
                  SizedBox(height: 16),
                  Strings.congratulations.text(32, 40, 700).c(context.colors.textStrong),
                  SizedBox(height: 16),
                  '$day-kun bajarildi'.text(24, 32, 700).c(context.colors.accentSub),
                  SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Strings.yourTrainingIsOver.text(16, 20, 500).c(context.colors.textSub),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTaskParametrs(Strings.exercises, '$taskCount ta', context),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: 12),
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.symmetric(
                                  vertical: BorderSide(color: context.colors.neutral200Stroke),
                                ),
                              ),
                              child: _buildTaskParametrs(
                                Strings.calories,
                                calories.toString(),
                                context,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildTaskParametrs(
                              Strings.duration,
                              duration.toString(),
                              context,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Strings.howAreYouFeeling.text(16, 20, 500).c(context.colors.textSub),
                      SizedBox(height: 8),
                      MoodSelector(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskParametrs(String parameterName, String parameterValue, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        parameterValue.text(16, 20, 500).c(context.colors.neutral900Primary),
        parameterName.text(14, 18, 400).c(context.colors.neutral600Secondary),
      ],
    );
  }
}
