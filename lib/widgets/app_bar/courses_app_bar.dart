import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

enum CoursesType { bulking, slimming }

class CoursesAppBar extends StatelessWidget {
  final CoursesType type;
  final void Function() openInfoSheet;

  const CoursesAppBar({super.key, required this.openInfoSheet, required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProfileRequest>(
      stream: profileStore.watch(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final gender = profile?.gender?.toLowerCase() == 'female' ? 'female' : 'male';

        return SafeArea(
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: ClipRect(
                  child: gender == 'female'
                      ? (type == CoursesType.slimming
                            ? Assets.images.femaleSlimmingBackgorund.image(width: double.infinity)
                            : Assets.images.femaleMassGainCourseBackground.image(width: double.infinity))
                      : (type == CoursesType.slimming
                            ? Assets.images.slimmingBackground.image(width: double.infinity)
                            : Assets.images.massGainCourseBackgorund.image(width: double.infinity)),
                ),
              ),
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: context.colors.white, shape: BoxShape.circle),
                        child: Assets.icons.arrowLeft.svg(),
                      ),
                    ),
                    GestureDetector(
                      onTap: openInfoSheet,
                      child: Container(
                        padding: const EdgeInsets.all(9),
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
      },
    );
  }
}
