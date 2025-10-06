import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/progress_button.dart';
import 'package:calora/common/widgets/button/simple_button.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/leave/leave_page.dart';
import 'package:calora/widgets/questions/question_progress_widget.dart';
import 'package:flutter/material.dart';

@RoutePage()
class TasksProcessPage extends StatelessWidget {
  final int current;
  final int total;
  final String taskName;
  final int duration;
  const TasksProcessPage({
    required this.duration,
    super.key,
    required this.current,
    required this.total,
    required this.taskName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: AppBar(
        leadingWidth: 40,
        leading: Row(
          children: [
            SizedBox(width: 16),
            GestureDetector(
              onTap: () => _showLeaveBottomSheet(context),
              child: Assets.icons.arrowLeft.svg(),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuestionProgressWidget(title: Strings.weStartedTheExercises, current: 1, total: 15),
              SizedBox(height: 28),
              Assets.images.taskVideo.image(),
              SizedBox(height: 12),
              taskName.text(20, 24, 700).c(context.colors.textStrong),
              SizedBox(height: 12),
              formatSeconds(duration).toString().text(32, 40, 700).c(context.colors.textStrong),
              SizedBox(height: 16),
              ProgressButton(
                duration: Duration(seconds: duration),
                onFinished: () {},
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SimpleButton(
                      text: 'Next',

                      onPressed: () {},
                      color: Colors.blue,
                      textColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: SimpleButton(
                      text: 'Next',
                      onPressed: () {},
                      color: Colors.blue,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return LeavePage();
      },
    );
  }

  String formatSeconds(int seconds) {
    final duration = Duration(seconds: seconds);

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));

    return "$minutes:$secs";
  }
}
