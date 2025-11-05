import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/course/course_cards.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'management/course_management.dart';
import 'management/course_manager.dart';

@RoutePage()
class CoursePage extends Managed<CourseManager, CourseState, CourseEffect> {
  const CoursePage({super.key});

  @override
  void init(context, manager) {
    manager.getCourses();
  }

  @override
  void listener(BuildContext context, CourseManager manager, CourseEffect effect) {
    effect.when(
      navigateToLessons: (course, lessons) {
        context.router.push(LessonBodyWidgetRoute(course: course, lessons: lessons));
      },
    );
    super.listener(context, manager, effect);
  }

  @override
  Widget builder(context, manager, state) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Assets.icons.background.image(fit: BoxFit.fill)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Strings.allCourses.text(17, 22, 600).c(context.colors.textStrong),
                  ),
                  const SizedBox(height: 8),
                  if (state.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    CourseCards(
                      courses: state.courses,
                      onTapCallbacks: {
                        for (final course in state.courses)
                          (course.id ?? 0): () {
                            manager.getLessonsAndNavigate(course: course);
                          },
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
