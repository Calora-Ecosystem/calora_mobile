import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/video_player/video_player_page.dart';
import 'package:calora/domain/model/course/video_course_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/courses_app_bar.dart';
import 'package:calora/widgets/info/course_info_widget.dart';
import 'package:calora/widgets/task/task_parametrs_widget.dart';
import 'package:flutter/material.dart';

class VideoCoursesBodyWidget extends StatelessWidget {
  final CoursesInfo course;
  final CoursesType type;

  VideoCoursesBodyWidget({super.key, required this.course, required this.type});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CoursesAppBar(openInfoSheet: () => openInfoSheet(context), type: type),
        Column(
          children: [
            SizedBox(height: 220),
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
                        children: [course.name.text(24, 32, 700), const SizedBox(width: 8), Assets.icons.lock.svg()],
                      ),
                      parameters: [
                        ParameterItem(name: 'Narxi', value: course.price),
                        ParameterItem(name: 'Darslar soni', value: '${course.videoCourses.length} ta'),
                        ParameterItem(name: Strings.duration, value: '492 min'),
                      ],
                      bottomLabel: Strings.videos,
                      bottomCount: course.videoCourses.length,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      fit: FlexFit.loose,
                      child: ListView.separated(
                        itemCount: course.videoCourses.length,
                        separatorBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: context.colors.neutral200Stroke, thickness: 1, height: 1),
                        ),
                        itemBuilder: (context, index) {
                          final courseInfo = course.videoCourses[index];
                          return GestureDetector(
                            onTap: () => openVideo(context, courseInfo.videoUrl),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    course.name.text(16, 20, 500).c(context.colors.neutral900Primary),
                                    const SizedBox(height: 8),
                                    formatDuration(
                                      course.duration,
                                    ).text(14, 18, 500).c(context.colors.neutral600Secondary),
                                  ],
                                ),
                                Spacer(),
                                course.purchased ? Assets.icons.lock.svg() : Assets.icons.lock.svg(),
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
    );
  }

  void openInfoSheet(BuildContext context) {
    context.showAppBottomSheet(child: CourseInfoWidget(), backgroundColor: context.colors.white);
  }

  void openVideo(BuildContext context, String url) {
    context.showAppBottomSheet(child: VideoPlayerPage(videoUrl: url));
  }

  String formatDuration(Duration d) {
    final hours = d.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
