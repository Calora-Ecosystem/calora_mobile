import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/progress_button.dart';
import 'package:calora/common/widgets/button/simple_button.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/tasks_process/management/tasks_process_management.dart';
import 'package:calora/presentation/tasks_process/management/tasks_process_manager.dart';
import 'package:calora/widgets/leave/leave_page.dart';
import 'package:calora/widgets/questions/question_progress_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class TasksProcessPage extends Managed<TasksProcessManager, TasksProcessState, TasksProcessEffect> {
  final List<ExercisesRequest> exercises;
  final WorkoutRequest workout;

  const TasksProcessPage({
    super.key,
    required this.exercises,
    required this.workout,
  });

  @override
  void init(BuildContext context, TasksProcessManager manager) {
    super.init(context, manager);
    manager.init(exercises, workoutId: workout.id);
  }

  @override
  void listener(BuildContext context, TasksProcessManager manager, TasksProcessEffect effect) {
    effect.when(
      showLeaveSheet: () async {
        await showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          isScrollControlled: true,
          backgroundColor: context.colors.white,
          builder: (_) => const LeavePage(),
        );
        manager.leaveSheetClosed();
      },
      navigateFinish: (calories, day, durationSeconds, taskCount) {
        context.router.push(
          FinishTaskRoute(
            calories: calories.toDouble(),
            day: workout.title,
            duration: durationSeconds,
            taskCount: taskCount,
          ),
        );
      },
    );
  }

  @override
  Widget builder(BuildContext context, TasksProcessManager manager, TasksProcessState state) {
    final ex = manager.currentExercise;
    if (!state.isInitialized || ex == null) {
      return Scaffold(
        backgroundColor: context.colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        manager.requestLeave();
      },
      child: Scaffold(
        backgroundColor: context.colors.white,
        appBar: AppBar(
          leadingWidth: 40,
          leading: Row(
            children: [
              const SizedBox(width: 16),
              GestureDetector(
                onTap: manager.requestLeave,
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
                  current: state.currentIndex + 1,
                  total: state.exercises.length,
                ),
                const SizedBox(height: 28),
                CustomCachedNetworkImage.banner(imageUrl: _assetUrlByType('Default', ex), height: 200),
                const SizedBox(height: 12),
                ex.title.text(20, 24, 700).c(context.colors.textStrong),
                const SizedBox(height: 12),
                Center(
                  child: (state.isCountType
                          ? 'x${state.remainingCount}'
                          : _formatSeconds(state.remainingSeconds))
                      .text(32, 40, 700)
                      .c(context.colors.textStrong),
                ),
                const SizedBox(height: 16),
                ProgressButton(
                  key: ValueKey(state.currentIndex),
                  duration: Duration(seconds: state.totalSeconds),
                  isPaused: state.isPaused,
                  onToggle: manager.togglePause,
                  onFinished: manager.next,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SimpleButton(
                        text: Strings.previous,
                        icon: state.currentIndex > 0 ? Assets.icons.previewIcon.svg() : Assets.icons.softPrevious.svg(),
                        onPressed: state.currentIndex > 0 ? manager.previous : () {},
                        color: context.colors.backgroundElevation,
                        textColor: state.currentIndex > 0 ? context.colors.textStrong : context.colors.textSub,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SimpleButton(
                        text: Strings.next,
                        icon: Assets.icons.nextIcon.svg(),
                        iconPosition: IconPosition.right,
                        onPressed: manager.next,
                        color: context.colors.backgroundElevation,
                        textColor: context.colors.textStrong,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _assetUrlByType(String type, ExercisesRequest exercises) {
    final item = exercises.assets.cast<dynamic>().firstWhere(
      (e) => (e.type?.toString() ?? e['type']?.toString())?.toLowerCase() == type.toLowerCase(),
      orElse: () => null,
    );
    if (item == null) return null;
    final url = (item.url?.toString() ?? item['url']?.toString())?.trim();
    return (url == null || url.isEmpty) ? null : url;
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).remainder(60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
