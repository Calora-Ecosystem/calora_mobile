import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart' show Strings;
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/simple_button.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/domain/model/profile/profile.dart';
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
  final LessonInfo lessonInfo;
  final Gender gender;
  final Level level;
  const TasksPage(this.level, this.lessonInfo, this.gender, {super.key});

  @override
  void init(BuildContext context, TasksManager manager) {
    super.init(context, manager);
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
                child: gender == Gender.female
                    ? Assets.images.femaleCourseImage.image(fit: BoxFit.cover)
                    : Assets.images.courseImage.image(fit: BoxFit.cover),
              ),
            ),
          ),
          Column(
            children: [
              LessonAppBar(
                percent: lessonInfo.level,
                title: lessonInfo.id.toString() + '-' + Strings.day.toLowerCase(),
                level: level,
                showIndicator: !lessonInfo.isDayOff,
                showSettings: false,
                onLevelChanged: (value) {},
              ),
              const SizedBox(height: 50),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: lessonInfo.isDayOff ? OffDayWidget() : TasksCards(lessonInfo: lessonInfo),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: lessonInfo.isDayOff
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SimpleButton(
                  text: Strings.start,
                  onPressed: () {
                    manager.initTasks(lessonInfo.tasks);
                    context.router.push(TasksProcessRoute(lessonInfo: lessonInfo));
                  },
                  color: context.colors.accentSub,
                  textColor: context.colors.textWhite,
                ),
              ),
            ),
    );
  }
}
