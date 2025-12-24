import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/progress_button.dart';
import 'package:calora/common/widgets/button/simple_button.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/tasks/management/tasks_management.dart';
import 'package:calora/presentation/tasks/management/tasks_manager.dart';
import 'package:calora/widgets/leave/leave_page.dart';
import 'package:calora/widgets/questions/question_progress_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class TasksProcessPage extends Managed<TasksManager, TasksState, TasksEffect> {
  final LessonInfo lessonInfo;

  const TasksProcessPage({super.key, required this.lessonInfo});

  @override
  void init(BuildContext context, TasksManager manager) {
    manager.initTasks(lessonInfo.tasks);
  }

  @override
  Widget builder(BuildContext context, TasksManager manager, TasksState state) {
    final currentTask = manager.currentTask;

    if (currentTask == null || state.tasks.isEmpty) {
      return Scaffold(body: Center(child: 'No tasks available'.text(16, 20, 400).c(Colors.black)));
    }

    final currentIndex = state.currentTaskIndex;
    final totalTasks = state.tasks.length;

    final totalCalories = lessonInfo.tasks.fold<double>(
      0,
      (sum, task) => sum + (lessonInfo.calories / lessonInfo.tasks.length),
    );

    final totalDuration = lessonInfo.tasks.fold<int>(0, (sum, task) => sum + task.duration);

    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: AppBar(
        leadingWidth: 40,
        leading: Row(
          children: [
            const SizedBox(width: 16),
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
              QuestionProgressWidget(
                title: Strings.weStartedTheExercises,
                current: currentIndex + 1,
                total: totalTasks,
              ),
              const SizedBox(height: 28),
              Assets.images.taskVideo.image(),
              const SizedBox(height: 12),
              currentTask.title.text(20, 24, 700).c(context.colors.textStrong),
              const SizedBox(height: 12),
              formatSeconds(currentTask.duration).text(32, 40, 700).c(context.colors.textStrong),
              const SizedBox(height: 16),
              ProgressButton(
                key: ValueKey(currentIndex),
                duration: Duration(seconds: currentTask.duration),
                onFinished: () {
                  manager.completeCurrentTask();
                  if (currentIndex == totalTasks - 1) {
                    context.router.push(
                      FinishTaskRoute(
                        calories: totalCalories,
                        day: 1,
                        duration: totalDuration,
                        taskCount: lessonInfo.tasks.length,
                      ),
                    );
                  } else {
                    manager.nextTask();
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SimpleButton(
                      text: Strings.previous,
                      icon: currentIndex > 0
                          ? Assets.icons.previewIcon.svg()
                          : Assets.icons.softPrevious.svg(),
                      onPressed: currentIndex > 0 ? () => manager.previousTask() : () {},
                      color: context.colors.backgroundElevation,
                      textColor: currentIndex > 0
                          ? context.colors.textStrong
                          : context.colors.textSub,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SimpleButton(
                      text: Strings.next,
                      icon: currentIndex < totalTasks - 1
                          ? Assets.icons.nextIcon.svg()
                          : Assets.icons.softNext.svg(),
                      iconPosition: IconPosition.right,
                      onPressed: currentIndex < totalTasks - 1 ? () => manager.nextTask() : () {},
                      color: context.colors.backgroundElevation,
                      textColor: currentIndex < totalTasks - 1
                          ? context.colors.textStrong
                          : context.colors.textSub,
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
      builder: (context) => const LeavePage(),
    );
  }

  String formatSeconds(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$secs';
  }
}
