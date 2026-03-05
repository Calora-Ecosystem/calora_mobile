import 'package:auto_route/auto_route.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/router/app_router.gr.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/common/widgets/snack_bar/custom_snack_bar.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/presentation/app/app/management/app_manager.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/lessons/management/lessons_manager.dart';
import 'package:calora/widgets/lessons/lesson_card.dart' show LessonCard;
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class LessonsCards extends StatelessWidget {
  final List<WorkoutRequest> workouts;
  final Level level;
  final bool isLoading;

  const LessonsCards({super.key, required this.level, required this.workouts, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final bool isUserPremium = context.read<AppManager>().state.isUserPremium;
    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: workouts.isEmpty ? 0 : workouts.length,
      itemBuilder: (context, index) {
        final int playableIndex = nextPlayableIndex(workouts);

        final bool lockedByPremium = !isUserPremium && index >= 3;

        final bool lockedByProgress = index > playableIndex;

        final bool visualLocked = lockedByPremium;
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
            onTap: () {
              if (lockedByPremium) {
                context.router.push(const PremiumFeaturesRoute());
                return;
              }
              if (lockedByProgress) {
                _showNeedFinishPrevSnack(context);
                return;
              }
              context.router.push(
                TasksRoute(level: level, workout: workout),
              ).then((_) {
                if (context.mounted) {
                  context.read<LessonsManager>().getWorkout(workout.courseId);
                }
              });
            },
            child: LessonCard(
              isLocked: visualLocked,
              workout: workout,
            ),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return SizedBox(height: 16);
      },
    );
  }

  int nextPlayableIndex(List<WorkoutRequest> workouts) {
    final i = workouts.indexWhere((w) => !w.isDone && w.doneItems < w.totalItems);
    return i == -1 ? workouts.length - 1 : i;
  }

  void _showNeedFinishPrevSnack(BuildContext context) {
    CustomSnackBar.showInfo(context, Strings.toDoExercise);
  }
}
