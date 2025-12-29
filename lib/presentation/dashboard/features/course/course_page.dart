import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/dashboard/features/course/management/course_management.dart';
import 'package:calora/presentation/dashboard/features/course/management/course_manager.dart';
import 'package:calora/widgets/course/course_card.dart';
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
  void listener(BuildContext context, CourseManager manager, CourseEffect effect) {
    super.listener(context, manager, effect);
  }

  @override
  Widget builder(BuildContext context, CourseManager manager, CourseState state) {
    final itemCount = state.isLoading ? 3 : state.courses.length;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Assets.icons.background.image(fit: BoxFit.fill),
          ),
          SafeArea(
            top: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: [
                /// ✅ APP BAR
                ValueListenableBuilder<bool>(
                  valueListenable: _isScrolled,
                  builder: (_, isScrolled, __) {
                    return SliverAppBar(
                      pinned: true,
                      backgroundColor: isScrolled ? context.colors.white : context.colors.transparent,
                      elevation: isScrolled ? 4 : 0,
                      scrolledUnderElevation: 4,
                      shadowColor: context.colors.black.withValues(alpha: 0.2),
                      surfaceTintColor: context.colors.white,
                      centerTitle: true,
                      title: Strings.allCourses.text(17, 22, 600).c(context.colors.textStrong),
                    );
                  },
                ),

                const SliverPadding(
                  padding: EdgeInsets.only(top: 16),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final course = state.isLoading ? CourseRequest() : state.courses[index];
                      return ShimmerWrapper(
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
                          onTap: () => context.router.push(LessonBodyWidgetRoute(course: course)),
                        ),
                      );
                    },
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
