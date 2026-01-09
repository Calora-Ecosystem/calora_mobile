import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/simple_button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/leave/leave_questions_page.dart';
import 'package:flutter/material.dart';

class LeavePage extends StatelessWidget {
  const LeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: double.infinity),
          SizedBox(
            height: 100,
            width: 100,
            child: Assets.images.exitImage.image(),
          ),
          const SizedBox(height: 12),
          Strings.willYouFinishTheExercises
              .text(20, 24, 700)
              .c(context.colors.textStrong),
          const SizedBox(height: 16),
          Strings.youMadeAGoodStart
              .text(16, 20, 400)
              .c(context.colors.textSub)
              .copyWith(textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SimpleButton(
            text: Strings.postpone,
            onPressed: () {
              context.router.pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaveQuestionsPage()),
              );
            },
            color: context.colors.backgroundElevation,
            textColor: context.colors.textStrong,
          ),
          const SizedBox(height: 12),
          SimpleButton(
            text: Strings.continueBtn,
            onPressed: () {
              context.router.pop();
            },
            color: context.colors.accentSub,
            textColor: context.colors.textWhite,
          ),
        ],
      ),
    );
  }
}
