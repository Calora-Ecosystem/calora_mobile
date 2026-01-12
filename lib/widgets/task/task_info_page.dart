import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/toggle_buttons.dart';
import 'package:calora/common/widgets/button/universal_stepper_widget.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart' hide StepperType;

class TaskInfoPage extends StatefulWidget {
  final ExercisesRequest exercises;

  const TaskInfoPage({
    super.key,
    required this.exercises,
  });

  @override
  State<TaskInfoPage> createState() => _TaskInfoPageState();
}

class _TaskInfoPageState extends State<TaskInfoPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              child: ToggleButtonsWidget(
                onChanged: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
                titles: [Strings.animation, Strings.videoExercises],
              ),
            ),
            const SizedBox(height: 12),
            if (selectedIndex == 0)
              Container(
                height: 200,
                color: context.colors.backgroundElevation,
                width: double.infinity,
                child: Assets.images.task.image(),
              ),
            // if (selectedIndex == 1) VideoPlayerPage(videoUrl: widget.exercises.assets),
            widget.exercises.title.text(20, 24, 700).c(context.colors.textStrong),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Strings.duration.text(16, 20, 500),
                UniversalStepperWidget(
                  type: StepperType.duration,
                  initialDuration: parseDuration(widget.exercises.duration),
                  stepDuration: const Duration(seconds: 5),
                  onChanged: (value) {},
                ),
              ],
            ),
            widget.exercises.description.text(14, 18, 400).c(context.colors.neutral600Secondary),
            Row(
              children: [
                Expanded(child: UniversalStepperWidget(type: StepperType.int, totalInt: 15)),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: context.colors.warningBase,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Strings.close
                          .text(16, 20, 500)
                          .c(context.colors.textWhite)
                          .copyWith(textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Duration parseDuration(String time) {
    final parts = time.split(':').map(int.parse).toList();

    return Duration(
      hours: parts[0],
      minutes: parts[1],
      seconds: parts[2],
    );
  }
}
