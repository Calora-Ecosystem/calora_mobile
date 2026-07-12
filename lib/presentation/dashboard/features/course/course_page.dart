import 'package:auto_route/auto_route.dart';
import 'package:calora/common/base/course_intro_store.dart';
import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/feature_tour/feature_tour.dart';
import 'package:calora/common/widgets/loading/default_refresh_indicator.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/course/management/course_management.dart';
import 'package:calora/presentation/dashboard/features/course/management/course_manager.dart';
import 'package:calora/widgets/course/course_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class CoursePage extends Managed<CourseManager, CourseState, CourseEffect> {
  CoursePage({super.key});

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);

  @override
  void init(BuildContext context, CourseManager manager) {
    manager.getCourses();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    _isScrolled.value = _scrollController.offset > 20;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _isScrolled.dispose();
    super.dispose();
  }

  @override
  void listener(
    BuildContext context,
    CourseManager manager,
    CourseEffect effect,
  ) {
    super.listener(context, manager, effect);
  }

  @override
  Widget builder(
    BuildContext context,
    CourseManager manager,
    CourseState state,
  ) {
    final itemCount = state.isLoading ? 3 : state.courses.length;
    return FeatureTourHost(
      tourId: 'tour_course',
      steps: _courseTourSteps(context),
      child: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.fill),
          ),
          SafeArea(
            top: false,
            child: DefaultRefreshIndicator(
              onRefresh: () async {
                manager.getCourses();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _isScrolled,
                    builder: (_, isScrolled, __) {
                      return SliverAppBar(
                        pinned: true,
                        backgroundColor: isScrolled
                            ? context.colors.white
                            : context.colors.transparent,
                        elevation: isScrolled ? 4 : 0,
                        scrolledUnderElevation: 4,
                        shadowColor: context.colors.black.withValues(alpha: 0.2),
                        surfaceTintColor: context.colors.white,
                        centerTitle: true,
                        title: Strings.allCourses.text(17, 22, 600).c(context.colors.textStrong),
                      );
                    },
                  ),
                  const SliverPadding(padding: EdgeInsets.only(top: 16)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: itemCount,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final course = state.isLoading ? CourseRequest() : state.courses[index];
                        final card = ShimmerWrapper(
                          loading: state.isLoading,
                          type: ShimmerType.backgroundElevation,
                          radius: 12,
                          shimmerChild: const ShimmerChild(
                            height: 160,
                            width: double.infinity,
                            radius: 16,
                          ),
                          child: CourseCard(
                            course: course,
                            onTap: () async {
                              if (course.type != 'Workout') {
                                context.router.push(VideoCourseBodyWidgetRoute(course: course));
                                return;
                              }
                              // Per-course gate: show the 3-step intro
                              // + progress screen the first time a user
                              // opens this specific workout course, then
                              // skip to LessonsRoute on every later tap.
                              // (Previously gated on `profile.physicalActivity`,
                              // which the main onboarding hardcodes to
                              // 'Healthy' — so the questionnaire never
                              // fired for anyone.)
                              final courseId = course.id ?? 0;
                              final alreadyDone =
                                  await CourseIntroStore().isCompleted(courseId);
                              if (!alreadyDone) {
                                context.router.push(
                                  CourseQuestionsRoute(
                                    courseId: courseId,
                                    imageUrl: course.subCoverImage ?? '',
                                  ),
                                );
                              } else {
                                context.router.push(
                                  LessonsRoute(
                                    courseId: courseId,
                                    imageUrl: course.subCoverImage ?? '',
                                  ),
                                );
                              }
                            },
                          ),
                        );
                        // Anchor the first card for the first-run feature tour.
                        return index == 0
                            ? KeyedSubtree(key: TourAnchors.courseFirst, child: card)
                            : card;
                      },
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// First-visit coach-mark for the Course tab, spotlighting the first lesson.
  List<FeatureTourStep> _courseTourSteps(BuildContext context) {
    Widget mi(IconData i) => Icon(i, size: 16, color: context.colors.accentSub);
    return [
      FeatureTourStep(
        targetKey: TourAnchors.courseFirst,
        icon: Icons.play_circle_fill_rounded,
        title: 'ft_course_title'.tr(),
        description: 'ft_course_desc'.tr(),
        bullets: [
          FeatureTourBullet(mi(Icons.play_circle_fill_rounded), 'ft_course_b1'.tr()),
          FeatureTourBullet(mi(Icons.lock_open_rounded), 'ft_course_b2'.tr()),
        ],
      ),
    ];
  }
}
