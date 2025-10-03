import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/widgets/course/course_card.dart';
import 'package:flutter/material.dart';

class CourseCards extends StatelessWidget {
  final VoidCallback onTapHealthyWeightLoss;
  final VoidCallback onTapHealthyMassGain;
  final VoidCallback onTapDay30WeightLossWorkout;
  final Gender gender;

  const CourseCards({
    super.key,
    required this.gender,
    required this.onTapHealthyWeightLoss,
    required this.onTapHealthyMassGain,
    required this.onTapDay30WeightLossWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseCard(
          onTap: onTapHealthyWeightLoss,
          title: Strings.healthyWeightLossClasses,
          description: Strings.videoLessonsOnlosingWeight,
          image: gender == Gender.female
              ? Assets.images.femaleWeightLoss
              : Assets.images.healthyWeightLoss,
        ),
        const SizedBox(height: 20),
        CourseCard(
          onTap: onTapHealthyMassGain,
          title: Strings.healthyMassGainClasses,
          description: Strings.videoLessonsOnbuildingBody,
          image: gender == Gender.female
              ? Assets.images.femaleGetMass
              : Assets.images.gainingHealthyMass,
        ),
        const SizedBox(height: 20),
        CourseCard(
          onTap: onTapDay30WeightLossWorkout,
          title: Strings.day30WeightLossWorkout,
          description: Strings.day30ExerciseWeightLossProgram,
          image: gender == Gender.female
              ? Assets.images.femaleChallenge
              : Assets.images.day30WeightLossWorkout,
        ),
      ],
    );
  }
}
