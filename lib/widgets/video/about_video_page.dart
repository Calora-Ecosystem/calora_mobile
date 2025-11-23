import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/video_player/video_player_page.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class AboutVideoPage extends StatelessWidget {
  final LessonRequest lesson;

  const AboutVideoPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          VideoPlayerPage(videoUrl: lesson.videoUrl ?? ''),
          Row(
            spacing: 8,
            children: [
              customIconTextBox(
                context: context,
                icon: Assets.icons.icPreview.svg(),
                text: Strings.previous,
                onTap: () {},
              ),
              customIconTextBox(context: context, icon: Assets.icons.icHelp.svg(), text: Strings.helpFaq, onTap: () {}),
              customIconTextBox(context: context, icon: Assets.icons.icNext.svg(), text: Strings.next, onTap: () {}),
            ],
          ),
          Strings.briefInformation.text(16, 20, 500).c(context.colors.textStrong),

          lesson.description.text(14, 18, 400),
        ],
      ),
    );
  }

  Widget customIconTextBox({
    required BuildContext context,
    required Widget icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: context.colors.backgroundElevation, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [icon, text.text(12, 16, 500).c(context.colors.textSub)]),
        ),
      ),
    );
  }
}
