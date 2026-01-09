import 'package:auto_route/auto_route.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/lessons/lesson_card.dart' show LessonCard;
import 'package:flutter/material.dart';

class LessonsCards extends StatelessWidget {
  final List<WorkoutRequest> workouts;
  final Level level;
  final bool isLoading;

  const LessonsCards({super.key, required this.level, required this.workouts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: workouts.isEmpty ? 3 : workouts.length,
        itemBuilder: (context, index) {
          final WorkoutRequest workout = workouts.isEmpty
              ? WorkoutRequest(
                  id: 1,
                  courseId: 1,
                  title: 'title',
                  hasRest: true,
                  totalItems: 1,
                  doneItems: 1,
                  isDone: true,
                  totalDurationInMin: 12,
                  totalMetrics: [],
                  order: 2,
                )
              : workouts[index];
          return ShimmerWrapper(
            loading: isLoading,
            shimmerChild: ShimmerChild(
              color: context.colors.backgroundElevation,
              height: 70,
            ),
            child: GestureDetector(
              onTap: () => context.router.push(TasksRoute(level: level, workout: workout)),
              child: LessonCard(
                workout: workout,
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(height: 16);
        },
      ),
    );
  }
}
