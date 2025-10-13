import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/indicator/card_indicator.dart';
import 'package:flutter/material.dart';

import '../train_level/train_level_page.dart';

class LessonAppBar extends StatelessWidget {
  final ValueChanged<int> onLevelChanged;
  final bool showSettings;
  final bool showIndicator;
  final double percent;
  final Level level;
  final String title;

  const LessonAppBar({
    this.percent = 0.5,
    super.key,
    required this.title,
    required this.onLevelChanged,
    required this.level,
    this.showSettings = true,
    this.showIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Birinchi qator: Back button va Settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(color: context.colors.white, shape: BoxShape.circle),
                    child: Assets.icons.arrowLeft.svg(),
                  ),
                ),
                if (showSettings)
                  GestureDetector(
                    onTap: () => _openSettings(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Assets.icons.settings.svg(),
                    ),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 12),
            // Ikkinchi qator: Rating/Title va Indicator
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RatingStars(level: level),
                          const SizedBox(width: 8),
                          Strings.startEasy.text(12, 14, 500).c(context.colors.textSub),
                        ],
                      ),
                      title.text(24, 32, 700).c(context.colors.accentSub).copyWith(maxLines: 2),
                    ],
                  ),
                ),
                if (showIndicator)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: SizedBox(width: 128, child: CardIndicator(percent: percent)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) async {
    final result = await showModalBottomSheet<int>(
      backgroundColor: context.colors.backgroundBase,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return TrainLevelPage(
          onSave: (value) {
            Navigator.pop(context, value);
          },
        );
      },
    );

    if (result != null) {
      onLevelChanged(result);
    }
  }
}
