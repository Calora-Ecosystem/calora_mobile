import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/simple_button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class LeaveQuestionsPage extends StatelessWidget {
  const LeaveQuestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Strings.whyDidYouFinishTheExercises.text(20, 24, 700).c(context.colors.textStrong),
            const SizedBox(height: 16),
            SimpleButton(
              text: Strings.iJustWantedToSee,
              onPressed: () {
                context.router.popUntil((route) => route.settings.name == TasksRoute.name);
              },
              color: context.colors.backgroundElevation,
              textColor: context.colors.textStrong,
            ),
            const SizedBox(height: 16),
            SimpleButton(
              text: Strings.exercisesAreVeryEasy,
              onPressed: () {
                context.router.popUntil((route) => route.settings.name == TasksRoute.name);
              },
              color: context.colors.backgroundElevation,
              textColor: context.colors.textStrong,
            ),
            const SizedBox(height: 16),
            SimpleButton(
              text: Strings.exercisesAreVeryDificult,
              onPressed: () {
                context.router.popUntil((route) => route.settings.name == TasksRoute.name);
              },
              color: context.colors.backgroundElevation,
              textColor: context.colors.textStrong,
            ),
          ],
        ),
      ),
    );
  }
}
