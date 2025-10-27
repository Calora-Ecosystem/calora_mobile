import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/widgets/course/course_card.dart';
import 'package:flutter/material.dart';

class CourseCards extends StatelessWidget {
  final VoidCallback onTapHealthyWeightLoss;
  final VoidCallback onTapHealthyMassGain;
  final VoidCallback onTapDay30WeightLossWorkout;

  const CourseCards({
    super.key,
    required this.onTapHealthyWeightLoss,
    required this.onTapHealthyMassGain,
    required this.onTapDay30WeightLossWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProfileRequest>(
      stream: profileStore.watch(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final gender = profile?.gender?.toLowerCase() == 'female' ? 'female' : 'male';

        return Column(
          children: [
            CourseCard(
              onTap: onTapHealthyWeightLoss,
              title: Strings.healthyWeightLossClasses,
              description: Strings.videoLessonsOnlosingWeight,
              image: gender == 'female'
                  ? Assets.images.femaleWeightLoss
                  : Assets.images.healthyWeightLoss,
            ),
            const SizedBox(height: 20),
            CourseCard(
              onTap: onTapHealthyMassGain,
              title: Strings.healthyMassGainClasses,
              description: Strings.videoLessonsOnbuildingBody,
              image: gender == 'female'
                  ? Assets.images.femaleGetMass
                  : Assets.images.gainingHealthyMass,
            ),
            const SizedBox(height: 20),
            CourseCard(
              onTap: onTapDay30WeightLossWorkout,
              title: Strings.day30WeightLossWorkout,
              description: Strings.day30ExerciseWeightLossProgram,
              image: gender == 'female'
                  ? Assets.images.femaleChallenge
                  : Assets.images.day30WeightLossWorkout,
            ),
          ],
        );
      },
    );
  }
}
