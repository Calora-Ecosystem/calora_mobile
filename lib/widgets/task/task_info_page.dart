import 'package:calora/common/extensions/assets_extension.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/button/toggle_buttons.dart';
import 'package:calora/common/widgets/button/universal_stepper_widget.dart';
import 'package:calora/common/widgets/video_player/animated_asset_view.dart';
import 'package:calora/common/widgets/video_player/youtube_inline_player.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart' hide StepperType;

class TaskInfoPage extends StatefulWidget {
  final ExercisesRequest exercises;

  const TaskInfoPage({super.key, required this.exercises});

  @override
  State<TaskInfoPage> createState() => _TaskInfoPageState();
}

class _TaskInfoPageState extends State<TaskInfoPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercises;
    final previewUrl = exercise.previewAssetUrl;
    final youtubeUrl = exercise.youtubeAssetUrl;
    final hasVideoTab = youtubeUrl != null && youtubeUrl.isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasVideoTab) ...[
              Align(
                child: ToggleButtonsWidget(
                  onChanged: (value) => setState(() => _selectedIndex = value),
                  titles: [Strings.animation, Strings.videoExercises],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedIndex == 0 || !hasVideoTab)
              AnimatedAssetView(
                key: ValueKey('preview-${exercise.id}'),
                url: previewUrl,
                height: 220,
              )
            else
              YoutubeInlinePlayer(youtubeUrl: youtubeUrl),
            const SizedBox(height: 12),
            exercise.title.text(20, 24, 700).c(context.colors.textStrong),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Strings.duration.text(16, 20, 500),
                UniversalStepperWidget(
                  type: StepperType.duration,
                  initialDuration: _parseDuration(exercise.duration),
                  stepDuration: const Duration(seconds: 5),
                  onChanged: (value) {},
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ExpandableDescription(text: exercise.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: UniversalStepperWidget(
                    type: StepperType.int,
                    totalInt: 15,
                  ),
                ),
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

  Duration _parseDuration(String time) {
    try {
      final parts = time.split(':').map(int.parse).toList();
      return Duration(
        hours: parts[0],
        minutes: parts[1],
        seconds: parts[2],
      );
    } catch (_) {
      return Duration.zero;
    }
  }
}

/// Collapsed by default to 3 lines with a "more / less" toggle. Skips
/// the toggle entirely for short descriptions that already fit.
class _ExpandableDescription extends StatefulWidget {
  final String text;

  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const _collapsedLines = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final color = context.colors.neutral600Secondary;
        final style = TextStyle(fontSize: 14, height: 18 / 14, color: color);

        final span = TextSpan(text: widget.text, style: style);
        final tp = TextPainter(
          text: span,
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final overflowed = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _collapsedLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflowed)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded ? 'Yopish' : 'Batafsil',
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.accentSub,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
