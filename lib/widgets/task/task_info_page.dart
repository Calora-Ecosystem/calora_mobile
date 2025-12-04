import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/universal_stepper_widget.dart';
import 'package:calora/common/widgets/button/toggle_buttons.dart';
import 'package:calora/common/widgets/video_player/video_player_page.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart' hide StepperType;

class TaskInfoPage extends StatefulWidget {
  final TaskInfo taskInfo;

  const TaskInfoPage({super.key, required this.taskInfo});

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
          children: [
            ToggleButtonsWidget(
              onChanged: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
              firstTitle: Strings.animation,
              secondTitle: Strings.videoExercises,
            ),
            const SizedBox(height: 20),
            if (selectedIndex == 0)
              Container(
                height: 200,
                color: context.colors.backgroundElevation,
                width: double.infinity,
                child: Assets.images.task.image(),
              ),
            if (selectedIndex == 1) VideoPlayerPage(videoUrl: widget.taskInfo.videoUrl),
            const SizedBox(height: 8),
            widget.taskInfo.descriptionTitle.text(20, 24, 700).c(context.colors.textStrong),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Strings.duration.text(16, 20, 500),
                UniversalStepperWidget(
                  type: StepperType.duration,
                  initialDuration: Duration(seconds: widget.taskInfo.duration),
                  stepDuration: const Duration(seconds: 5),
                  onChanged: (value) {},
                ),
              ],
            ),
            const SizedBox(height: 8),
            DescriptionWidget(),
            const SizedBox(height: 8),
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
}

class DescriptionWidget extends StatelessWidget {
  const DescriptionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Planka mashqi — tanani to‘g‘ri holatda ushlab turishni talab qiladigan statik mashq. "
              "Bu mashq qorin muskullarini, bel, orqa va yelka mushaklarini mustahkamlaydi.",
        ),
        const Text(
          "• Bajarilish tartibi:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        _bullet("a. Tizzadan turib, tirsaklarni yelkalar ostiga qo‘ying."),
        _bullet("b. Oyoqlarni orqaga cho‘zib, tanani tekis chiziqda ushlang."),
        _bullet("c. Qorin mushaklarini tarang qilib, belni bukmasdan yoki ko‘tarmasdan ushlang."),
        _bullet("d. Belgilangan vaqt davomida (masalan, 30–60 soniya) shu holatda turing."),
        const Text(
          "• Asosiy foydasi:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        _bullet("Qorin mushaklarini kuchaytiradi"),
        _bullet("Bel va orqa qismini mustahkamlaydi"),
      ],
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
