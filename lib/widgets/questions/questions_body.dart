import 'dart:developer';

import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/questions/questions/management/questions_manager.dart';
import 'package:calora/widgets/questions/common_textfield.dart';
import 'package:calora/widgets/questions/date_picker.dart';
import 'package:calora/widgets/questions/gender.dart';
import 'package:calora/widgets/questions/goals.dart';
import 'package:calora/widgets/questions/questions_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import '../../common/gen/assets.gen.dart';

class QuestionsBody extends StatefulWidget {
  const QuestionsBody({super.key});

  @override
  State<QuestionsBody> createState() => _QuestionsBodyState();
}

class _QuestionsBodyState extends State<QuestionsBody> {
  List<String> goals = [Strings.weightLoss, Strings.maintainingBody, Strings.muscleDevelopment];
  List<String> activities = [
    Strings.lowActivity,
    Strings.averageActivity,
    Strings.highActivity,
    Strings.veryHighActivity,
  ];
  late final TextEditingController nameController;
  late final TextEditingController heightController;
  late final TextEditingController weightController;
  late final TextEditingController targetWeightController;
  late final TextEditingController activityHoursController;

  @override
  void initState() {
    super.initState();
    log('initState');
    final state = context.read<QuestionsManager>().state;
    nameController = TextEditingController(text: state.answers?.name ?? '');
    heightController = TextEditingController(text: state.answers?.height?.toString() ?? '');
    weightController = TextEditingController(text: state.answers?.weight?.toString() ?? '');
    targetWeightController = TextEditingController(
      text: state.answers?.targetWeight?.toString() ?? '',
    );
    activityHoursController = TextEditingController(
      text: state.answers?.activityHours?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.read<QuestionsManager>();
    return IndexedStack(
      index: manager.state.currentIndex,
      children: [
        QuestionWidget(
          questionText: Strings.whatIsYourName,
          child: CustomTextField(
            controller: nameController,
            hintText: '-',
            onChanged: (val) => manager.setAnswer(name: val),
          ),
          icon: Assets.icons.human.svg(),
        ),

        // 1 - Gender
        QuestionWidget(
          questionText: Strings.whatIsYourGender,
          child: Gender(onGenderSelected: (val) => manager.setAnswer(gender: val)),
          icon: Assets.icons.gender.svg(),
        ),

        // 2 - Goals
        QuestionWidget(
          questionText: Strings.chooseYourGoals,
          child: Goals(
            onGoalSelected: (val) => manager.setAnswer(purposeIds: [val]),
            goals: goals,
          ),
          icon: Assets.icons.goal.svg(),
        ),

        // 3 - BirthDate
        QuestionWidget(
          questionText: Strings.whenWhereYouBorn,
          child: DatePickerScreen(onDateChanged: (val) => manager.setAnswer(birthDate: val)),
          icon: Assets.icons.calendar.svg(),
        ),

        // 4 - Height
        QuestionWidget(
          questionText: Strings.whatIsYourHeight,
          child: CustomTextField(
            hintText: '- sm',
            controller: heightController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => manager.setAnswer(height: double.tryParse(val)),
          ),
          icon: Assets.icons.ruler.svg(),
        ),

        // 5 - Weight
        QuestionWidget(
          questionText: Strings.howManyKilograms,
          child: CustomTextField(
            hintText: '- kg',
            controller: weightController,
            keyboardType: TextInputType.number,
            onChanged: (val) => manager.setAnswer(weight: double.tryParse(val)),
          ),
          icon: Assets.icons.weight.svg(),
        ),

        // 6 - Target Weight
        QuestionWidget(
          questionText: Strings.weightChange,
          child: CustomTextField(
            hintText: '- kg',
            controller: targetWeightController,
            keyboardType: TextInputType.number,
            onChanged: (val) => manager.setAnswer(targetWeight: double.tryParse(val)),
          ),
          icon: Assets.icons.weight.svg(),
        ),

        // 7 - Activity Hours
        QuestionWidget(
          questionText: Strings.activePerDay,
          child: Goals(
            onGoalSelected: (val) => manager.setAnswer(activityHours: val.toString()),
            goals: activities,
          ),
          icon: Assets.icons.activity.svg(),
        ),
      ],
    );
  }
}
