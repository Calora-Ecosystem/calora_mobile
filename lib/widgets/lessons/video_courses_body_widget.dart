import 'package:auto_route/annotations.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/courses_app_bar.dart';
import 'package:calora/widgets/info/course_info_widget.dart';
import 'package:calora/widgets/task/task_parametrs_widget.dart';
import 'package:calora/widgets/video/about_video_page.dart';
import 'package:flutter/material.dart';

import '../../domain/model/lesson/lesson_request.dart' show LessonRequest;

@RoutePage()
class LessonBodyWidgetPage extends StatefulWidget {
  final CourseRequest course;
  final List<LessonRequest> lessons;
  final bool isPurchased;

  const LessonBodyWidgetPage({super.key, required this.course, required this.lessons, this.isPurchased = false});

  @override
  State<LessonBodyWidgetPage> createState() => _LessonBodyWidgetPageState();
}

class _LessonBodyWidgetPageState extends State<LessonBodyWidgetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CoursesAppBar(
            openInfoSheet: () => openInfoSheet(context, widget.course.description ?? ''),
            imageUrl: widget.course.subCoverImage ?? '',
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
                            Expanded(child: widget.course.title.text(24, 32, 700)),
                            const SizedBox(width: 8),
                            Assets.icons.lock.svg(),
                          ],
                        ),
                        parameters: [
                          ParameterItem(name: 'Narxi', value: '${widget.course.price} so‘m'),
                          ParameterItem(name: 'Darslar soni', value: '${widget.lessons.length} ta'),
                          ParameterItem(name: Strings.duration, value: getTotalDuration()),
                        ],
                        bottomLabel: Strings.videos,
                        bottomCount: widget.lessons.length,
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        fit: FlexFit.loose,
                        child: ListView.separated(
                          itemCount: widget.lessons.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: context.colors.neutral200Stroke, thickness: 1, height: 1),
                          ),
                          itemBuilder: (context, index) {
                            final lesson = widget.lessons[index];
                            return GestureDetector(
                              onTap: () {
                                if (lesson.isFree) openVideo(context, lesson);
                              },
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
                                  if (!lesson.isFree) Assets.icons.lock.svg(),
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

  void openInfoSheet(BuildContext context, String description) {
    context.showAppBottomSheet(
      child: CourseInfoWidget(description: description),
      backgroundColor: context.colors.white,
    );
  }

  void openVideo(BuildContext context, LessonRequest lesson) {
    context.showAppBottomSheet(child: AboutVideoPage(lesson: lesson));
  }

  String getTotalDuration() {
    if (widget.lessons.isEmpty) return '0 min';
    final totalMinutes = widget.lessons.fold<int>(0, (sum, e) {
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
