import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/button/button.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart' show LessonRequest;
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/courses_app_bar.dart';
import 'package:calora/widgets/info/course_info_widget.dart';
import 'package:calora/widgets/lessons/video_course_body/management/video_course_body_management.dart';
import 'package:calora/widgets/lessons/video_course_body/management/video_course_body_manager.dart';
import 'package:calora/widgets/task/task_parametrs_widget.dart';
import 'package:calora/widgets/video/about_video_page.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class VideoCourseBodyWidgetPage
    extends Managed<VideoCourseBodyManager, VideoCourseBodyState, VideoCourseBodyEffect> {
  final CourseRequest course;
  final bool isPurchased;

  VideoCourseBodyWidgetPage({
    super.key,
    required this.course,
    this.isPurchased = false,
  }) : super();

  @override
  void init(BuildContext context, VideoCourseBodyManager manager) {
    final isUserPremium = context.read<AppManager>().state.isUserPremium;
    manager.setPurchased(isPurchased || isUserPremium);
    manager.getVideoCourse(course.id ?? 0);
    super.init(context, manager);
  }

  @override
  void listener(
    BuildContext context,
    VideoCourseBodyManager manager,
    VideoCourseBodyEffect effect,
  ) {
    super.listener(context, manager, effect);
    effect.when(
      openInfoSheet: (description) => _openInfoSheet(context, description),
      openVideo: (lesson, index) => _openVideo(context, lesson, index, manager),
      showNeedFinishPrevious: () =>
          CustomSnackBar.showInfo(context, Strings.watchThisVideoPreviousVideo),
      showError: (message) => CustomSnackBar.show(context, message),
    );
  }

  @override
  Widget builder(
    BuildContext context,
    VideoCourseBodyManager manager,
    VideoCourseBodyState state,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          CoursesAppBar(
            openInfoSheet: () => _openInfoSheet(context, course.description ?? ''),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TaskParametersWidget(
                        title: Row(
                          children: [
                            Expanded(child: course.title.text(24, 32, 700)),
                            const SizedBox(width: 8),
                            if (!state.isPurchased)
                              Assets.icons.lock.svg()
                            else
                              Assets.icons.money.svg(),
                          ],
                        ),
                        parameters: [
                          ParameterItem(
                            name: Strings.price,
                            value: '${course.price} so‘m',
                          ),
                          ParameterItem(
                            name: Strings.numberOfLessons,
                            value: '${state.lessons.length} ta',
                          ),
                          ParameterItem(
                            name: Strings.duration,
                            value: _getTotalDuration(state.lessons),
                          ),
                        ],
                        bottomLabel: Strings.videos,
                        bottomCount: state.lessons.length,
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.separated(
                          itemCount: state.isLoading ? 3 : state.lessons.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: context.colors.neutral200Stroke,
                              thickness: 1,
                              height: 1,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final lesson = state.isLoading
                                ? const LessonRequest(
                                    id: 0,
                                    courseId: 0,
                                    duration: '0',
                                    isFree: true,
                                    title: 'title',
                                    description: 'description',
                                    order: 1,
                                    isFinished: true,
                                    assets: [],
                                  )
                                : state.lessons[index];

                            final showLock = !lesson.isFree && !state.isPurchased;

                            return ShimmerWrapper(
                              shimmerChild: ShimmerChild(
                                height: 48,
                                width: double.infinity,
                              ),
                              loading: state.isLoading,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (showLock) {
                                    context.router.push(const PremiumFeaturesRoute());
                                    return;
                                  }
                                  manager.onVideoTapped(lesson, index);
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      height: 48,
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
                                          lesson.title
                                              .text(16, 20, 500)
                                              .c(context.colors.neutral900Primary),
                                          const SizedBox(height: 8),
                                          lesson.duration
                                              .text(14, 18, 500)
                                              .c(context.colors.neutral600Secondary),
                                        ],
                                      ),
                                    ),
                                    if (showLock)
                                      Assets.icons.lock.svg()
                                    else if (lesson.isFinished)
                                      Assets.icons.done.svg(),
                                  ],
                                ),
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
      bottomNavigationBar: !state.isPurchased
          ? SafeArea(
              child: Button(
                onPressed: () => context.router.push(const PremiumFeaturesRoute()),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                text: Strings.purchase,
              ),
            )
          : null,
    );
  }

  void _openInfoSheet(BuildContext context, String description) {
    context.showAppBottomSheet(
      child: CourseInfoWidget(description: description),
      backgroundColor: context.colors.white,
    );
  }

  void _openVideo(
    BuildContext context,
    LessonRequest lesson,
    int index,
    VideoCourseBodyManager manager,
  ) {
    context.showAppBottomSheet(
      child: AboutVideoPage(
        onVideoCompleted: () {
          manager.videoCompleted(lesson.id);
        },
        lesson: lesson,
        index: index,
      ),
    );
  }

  String _getTotalDuration(List<LessonRequest> lessons) {
    if (lessons.isEmpty) return '0m';

    final totalSeconds = lessons.fold<int>(0, (sum, e) {
      final parts = e.duration.split(':');

      if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = int.tryParse(parts[2]) ?? 0;
        return sum + (h * 3600 + m * 60 + s);
      } else if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return sum + (h * 3600 + m * 60);
      } else if (parts.length == 1) {
        final s = int.tryParse(parts[0]) ?? 0;
        return sum + s;
      }

      return sum;
    });

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
