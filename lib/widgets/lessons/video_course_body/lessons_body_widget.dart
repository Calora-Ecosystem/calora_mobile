import 'package:auto_route/annotations.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart' show LessonRequest;
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/courses_app_bar.dart';
import 'package:calora/widgets/info/course_info_widget.dart';
import 'package:calora/widgets/task/task_parametrs_widget.dart';
import 'package:calora/widgets/video/about_video_page.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'management/lesson_body_management.dart';
import 'management/lesson_body_manager.dart';

@RoutePage()
class LessonBodyWidgetPage extends Managed<LessonBodyManager, LessonBodyState, LessonBodyEffect> {
  final CourseRequest course;
  final bool isPurchased;

  LessonBodyWidgetPage({
    super.key,
    required this.course,
    this.isPurchased = false,
  }) : super();

  @override
  void listener(BuildContext context, LessonBodyManager manager, LessonBodyEffect effect) {
    super.listener(context, manager, effect);
    effect.when(
      openInfoSheet: (description) => _openInfoSheet(context, description),
      openVideo: (lesson, index) => _openVideo(context, lesson, index),
    );
  }

  @override
  Widget builder(BuildContext context, LessonBodyManager manager, LessonBodyState state) {
    final course = state.course;
    if (course == null) return const SizedBox.shrink();

    return Scaffold(
      body: Stack(
        children: [
          CoursesAppBar(
            openInfoSheet: manager.onInfoTapped,
            imageUrl: course.subCoverImage ?? '',
          ),
          Column(
            children: [
              const SizedBox(height: 220),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TaskParametersWidget(
                        title: Row(
                          children: [
                            Expanded(child: course.title.text(24, 32, 700)),
                            const SizedBox(width: 8),
                            if (!state.isPurchased) Assets.icons.lock.svg(),
                          ],
                        ),
                        parameters: [
                          ParameterItem(name: 'Narxi', value: '${course.price} so‘m'),
                          ParameterItem(name: 'Darslar soni', value: '${state.lessons.length} ta'),
                          ParameterItem(name: Strings.duration, value: _getTotalDuration(state.lessons)),
                        ],
                        bottomLabel: Strings.videos,
                        bottomCount: state.lessons.length,
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.separated(
                          itemCount: state.lessons.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: context.colors.neutral200Stroke, thickness: 1, height: 1),
                          ),
                          itemBuilder: (context, index) {
                            final lesson = state.lessons[index];
                            return GestureDetector(
                              onTap: () => manager.onVideoTapped(lesson, index),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.colors.backgroundElevation,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Assets.icons.videoIcon.svg(),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        lesson.title.text(16, 20, 500).c(context.colors.neutral900Primary),
                                        const SizedBox(height: 8),
                                        lesson.duration.text(14, 18, 500).c(context.colors.neutral600Secondary),
                                      ],
                                    ),
                                  ),
                                  if (!lesson.isFree && !state.isPurchased) Assets.icons.lock.svg(),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openInfoSheet(BuildContext context, String description) {
    context.showAppBottomSheet(
      child: CourseInfoWidget(description: description),
      backgroundColor: context.colors.white,
    );
  }

  void _openVideo(BuildContext context, LessonRequest lesson, int index) {
    context.showAppBottomSheet(
      child: AboutVideoPage(lesson: lesson, index: index),
    );
  }

  String _getTotalDuration(List<LessonRequest> lessons) {
    if (lessons.isEmpty) return '0 min';
    final totalMinutes = lessons.fold<int>(0, (sum, e) {
      final parts = e.duration.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return sum + (h * 60 + m);
      }
      return sum;
    });
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
