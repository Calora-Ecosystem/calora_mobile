import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/metrics_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/common/widgets/video_player/animated_asset_view.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/task/task_info_page.dart';
import 'package:calora/widgets/task/task_parametrs_widget.dart';
import 'package:calora/widgets/train_level/train_level_page.dart';
import 'package:flutter/material.dart';

class TasksCards extends StatelessWidget {
  final WorkoutRequest workout;
  final List<ExercisesRequest> exercises;
  final bool loading;
  final Level level;
  final ValueChanged<int> onLevelChanged;

  const TasksCards({
    super.key,
    required this.workout,
    required this.exercises,
    required this.loading,
    required this.level,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TaskParametersWidget(
          title: Strings.discoverWorkoutExercises(workoutTitle: workout.title).text(20, 24, 600),
          parameters: [
            ParameterItem(name: Strings.degree, value: _levelLabel(level)),
            ParameterItem(name: Strings.kcal, value: '${workout.totalMetrics.sumOf('Kcal')}'),
            ParameterItem(name: Strings.duration, value: '${workout.totalDurationInMin}'),
          ],
          bottomLabel: Strings.exercises,
          bottomCount: exercises.length,
          onChangePressed: () => _openSettings(context, level.index),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            return _ExerciseCard(
              exercise: exercises[index],
              loading: loading,
              onTap: () => _showTask(context, exercises[index]),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 16),
        ),
      ],
    );
  }

  void _showTask(BuildContext context, ExercisesRequest exercise) {
    context.showAppBottomSheet(child: TaskInfoPage(exercises: exercise));
  }

  void _openSettings(BuildContext context, int currentLevel) async {
    final result = await showModalBottomSheet<int>(
      backgroundColor: context.colors.backgroundBase,
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (_) => TrainLevelPage(currentLevel: currentLevel),
    );
    if (result != null) onLevelChanged(result);
  }

  String _levelLabel(Level level) {
    switch (level) {
      case Level.minimal:
        return Strings.minimal;
      case Level.less:
        return Strings.less;
      case Level.medium:
        return Strings.medium;
      case Level.high:
        return Strings.high;
      case Level.maximal:
        return Strings.maximal;
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExercisesRequest exercise;
  final bool loading;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      loading: loading,
      shimmerChild: ShimmerChild(
        height: 88,
        color: context.colors.backgroundElevation,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.backgroundElevation,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Backend's `Default` asset is either a `.gif` (rendered
              // via CachedNetworkImage) or a `.mp4` (looping muted
              // video). AnimatedAssetView branches on the extension
              // and manages controller lifecycle so cards scrolling
              // past `cacheExtent` release their resources.
              SizedBox(
                width: 64,
                height: 64,
                child: AnimatedAssetView(
                  key: ValueKey(exercise.id),
                  url: exercise.previewAssetUrl,
                  height: 64,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    exercise.title
                        .text(16, 20, 500)
                        .c(context.colors.textStrong)
                        .copyWith(overflow: TextOverflow.ellipsis, maxLines: 1),
                    const SizedBox(height: 6),
                    _MetricsRow(exercise: exercise),
                  ],
                ),
              ),
              if (exercise.isDone)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.check_circle,
                    size: 22,
                    color: context.colors.accentSub,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final ExercisesRequest exercise;

  const _MetricsRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final computation = exercise.computation;
    if (computation == null) {
      return exercise.duration.text(14, 18, 500).c(context.colors.textSub);
    }

    final isDuration = computation.computationType == ComputationType.duration;
    return _Badge(
      icon: isDuration ? Icons.timer_outlined : Icons.repeat,
      label: computation.format(
        durationUnit: Strings.minute,
        countUnit: Strings.times,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.textSub),
          const SizedBox(width: 4),
          label.text(12, 14, 500).c(context.colors.textSub),
        ],
      ),
    );
  }
}
