import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CoursesAppBar extends StatelessWidget {
  final Future<Gender> gender;
  final void Function() openInfoSheet;
  const CoursesAppBar({super.key, required this.openInfoSheet, required this.gender});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          gender == Gender.Female
              ? Assets.images.femaleSlimmingBackgorund.image(fit: BoxFit.cover)
              : Assets.images.slimmingBackground.image(fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
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
                GestureDetector(
                  onTap: () => openInfoSheet(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(color: context.colors.white, shape: BoxShape.circle),
                    child: Assets.icons.informationCircle.svg(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
