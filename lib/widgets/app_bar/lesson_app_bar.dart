import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/common/widgets/rating/rating_stars.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/indicator/card_indicator.dart';
import 'package:flutter/material.dart';

import '../train_level/train_level_page.dart';

class LessonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<int> onLevelChanged;
  final Level level;

  const LessonAppBar({super.key, required this.onLevelChanged, required this.level});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Assets.icons.arrowLeft.svg(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      RatingStars(level: level),
                      const SizedBox(width: 8),
                      Strings.startEasy.text(12, 14, 500).c(context.colors.textSub),
                    ],
                  ),
                  Strings.changeWithin30Days
                      .text(24, 32, 700)
                      .c(context.colors.accentSub)
                      .copyWith(maxLines: 2),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: CardIndicator(percent: 0.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(230);

  void _openSettings(BuildContext context) async {
    final result = await showModalBottomSheet<int>(
      backgroundColor: context.colors.backgroundBase,
      context: context,
      isScrollControlled: true,
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
