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
              if (gender == 'female')
                (type == CoursesType.slimming
                    ? Assets.images.femaleSlimmingBackgorund.image(fit: BoxFit.cover)
                    : Assets.images.femaleMassGainCourseBackground.image(fit: BoxFit.cover))
              else
                (type == CoursesType.slimming
                    ? Assets.images.slimmingBackground.image(fit: BoxFit.cover)
                    : Assets.images.massGainCourseBackgorund.image(fit: BoxFit.cover)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    GestureDetector(
                      onTap: openInfoSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colors.white,
                          shape: BoxShape.circle,
                        ),
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
