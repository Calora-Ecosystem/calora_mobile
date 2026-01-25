import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/common/extensions/metrics_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/image/custom_cached_network_image.dart';
import 'package:calora/common/widgets/loading/shimmer.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/task/task_info_page.dart';
import 'package:calora/widgets/task/task_parametrs_widget.dart';
import 'package:flutter/material.dart';

class TasksCards extends StatelessWidget {
  final WorkoutRequest workout;
  final List<ExercisesRequest> exercises;
  final bool loading;
  final Level level;

  TasksCards({
    super.key,
    required this.workout,
    required this.exercises,
    required this.loading,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TaskParametersWidget(
          title: '${workout.title} mashqlari bilan tanishing '.text(20, 24, 600),
          parameters: [
            ParameterItem(name: Strings.degree, value: levelToLocalizedString(level)),
            ParameterItem(name: Strings.kcal, value: '${workout.totalMetrics.sumOf('Kcal')}'),
            ParameterItem(name: Strings.duration, value: '${workout.totalDurationInMin}'),
          ],
          bottomLabel: Strings.exercises,
          bottomCount: exercises.length,
          onChangePressed: () {},
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            return ShimmerWrapper(
              loading: loading,
              shimmerChild: ShimmerChild(
                height: 70,
                color: context.colors.backgroundElevation,
              ),
              child: GestureDetector(
                onTap: () => _showTask(context, exercises[index]),
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.backgroundElevation,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CustomCachedNetworkImage.banner(
                        imageUrl: _assetUrlByType('Default', exercises[index]),
                        height: 56,
                        width: 56,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: .start,
                          spacing: 8,
                          children: [
                            exercises[index].title
                                .text(16, 20, 500)
                                .c(context.colors.textStrong)
                                .copyWith(overflow: .ellipsis, maxLines: 1),
                            exercises[index].duration.text(14, 18, 500).c(context.colors.textSub),
                          ],
                        ),
                      ),
                      if (exercises[index].isDone)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Assets.icons.twoDone.svg(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return SizedBox(height: 16);
          },
        ),
      ],
    );
  }

  void _showTask(BuildContext context, ExercisesRequest exercises) {
    context.showAppBottomSheet(child: TaskInfoPage(exercises: exercises));
  }

  bool isLocked(int index, bool isUserPremium) {
    if (isUserPremium) return false;
    return index >= 3;
  }

  String? _assetUrlByType(String type, ExercisesRequest exercises) {
    final item = exercises.assets.cast<dynamic>().firstWhere(
      (e) => (e.type?.toString() ?? e['type']?.toString())?.toLowerCase() == type.toLowerCase(),
      orElse: () => null,
    );
    if (item == null) return null;
    final url = (item.url?.toString() ?? item['url']?.toString())?.trim();
    return (url == null || url.isEmpty) ? null : url;
  }

  String levelToLocalizedString(Level level) {
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
