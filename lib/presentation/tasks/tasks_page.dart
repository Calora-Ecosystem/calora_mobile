import 'package:auto_route/annotations.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart' show Strings;
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/tasks/management/tasks_management.dart';
import 'package:calora/presentation/tasks/management/tasks_manager.dart';
import 'package:calora/widgets/app_bar/lesson_app_bar.dart';
import 'package:calora/widgets/lessons/tasks_cards.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class TasksPage extends Managed<TasksManager, TasksState, TasksEffect> {
  final List<TaskInfo> tasks;
  final int id;
  final Level level;
  const TasksPage(this.tasks, this.id, this.level, {super.key});

  @override
  Widget builder(BuildContext context, TasksManager manager, TasksState state) {
    return Scaffold(
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
                title: id.toString() + '-' + Strings.day.toLowerCase(),
                level: level,
                showSettings: false,
                onLevelChanged: (value) {},
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [Expanded(child: TasksCards(tasks: tasks))],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    ;
  }
}
