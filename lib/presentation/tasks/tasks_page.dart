import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/simple_button.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/tasks/management/tasks_management.dart';
import 'package:calora/presentation/tasks/management/tasks_manager.dart';
import 'package:calora/widgets/app_bar/lesson_app_bar.dart';
import 'package:calora/widgets/lessons/tasks_cards.dart';
import 'package:calora/widgets/task/off_day_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class TasksPage extends Managed<TasksManager, TasksState, TasksEffect> {
  final WorkoutRequest workout;
  final Level level;

  const TasksPage({super.key, required this.workout, required this.level});

  @override
  void init(BuildContext context, TasksManager manager) {
    super.init(context, manager);
    manager.getExercises(workout.id);
  }

  @override
  Widget builder(BuildContext context, TasksManager manager, TasksState state) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.colors.accentDisabled,
      body: Stack(
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                height: 200,
                width: 200,
                child: Assets.images.courseImage.image(fit: BoxFit.cover),
              ),
            ),
          ),
          Column(
            children: [
              LessonAppBar(
                percent: workout.doneItems / workout.totalItems,
                title: workout.title,
                level: level,
                showIndicator: false,
                showSettings: false,
                onLevelChanged: (value) {},
              ),
              const SizedBox(height: 50),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: workout.hasRest
                      ? const OffDayWidget()
                      : TasksCards(
                          loading: state.isLoading,
                          exercises: state.exercises,
                          workout: workout,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: workout.hasRest
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SimpleButton(
                  text: Strings.start,
                  onPressed: () => context.router.push(TasksProcessRoute()),
                  color: context.colors.accentSub,
                  textColor: context.colors.textWhite,
                ),
              ),
            ),
    );
  }
}
