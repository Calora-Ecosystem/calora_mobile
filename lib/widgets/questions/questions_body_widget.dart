import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/questions/questions.dart';
import 'package:calora/presentation/questions/questions/management/questions_manager.dart';
import 'package:calora/widgets/questions/custom_text_field.dart';
import 'package:calora/widgets/questions/date_picker_widget.dart';
import 'package:calora/widgets/questions/gender_widget.dart';
import 'package:calora/widgets/questions/purposes_widget.dart';
import 'package:calora/widgets/questions/questions_widget.dart' show QuestionWidget;
import 'package:flutter/material.dart';
import 'package:management/management.dart';

class QuestionsBodyWidget extends StatefulWidget {
  const QuestionsBodyWidget({super.key});

  @override
  State<QuestionsBodyWidget> createState() => _QuestionsBodyWidgetState();
}

class _QuestionsBodyWidgetState extends State<QuestionsBodyWidget> {
  List<String> goals = [Strings.weightLoss, Strings.maintainingBody, Strings.muscleDevelopment];
  List<String> activities = [
    Strings.minActivity,
    Strings.lowActivity,
    Strings.averageActivity,
    Strings.highActivity,
    Strings.veryHighActivity,
  ];

  @override
  Widget build(BuildContext context) {
    final manager = context.read<QuestionsManager>();
    return IndexedStack(
      index: manager.state.currentIndex,
      children: [
        QuestionWidget(
          questionText: Strings.whatIsYourName,
          child: CustomTextField(
            keyboardType: TextInputType.text,
            hintText: '-',
            onChanged: (val) => manager.setAnswer(Questions(name: val)),
          ),
          icon: Assets.icons.human.svg(),
        ),

        // 1 - Gender
        QuestionWidget(
          questionText: Strings.whatIsYourGender,
          child: GenderWidget(onGenderSelected: (val) => manager.setAnswer(Questions(gender: val))),
          icon: Assets.icons.gender.svg(),
        ),

        // 2 - Goals
        QuestionWidget(
          questionText: Strings.chooseYourGoals,
          child: PurposesWidget(
            onPurposeSelected: (val) => manager.setAnswer(Questions(purposeIds: [val])),
            goals: goals,
          ),
          icon: Assets.icons.goal.svg(),
        ),

        // 3 - BirthDate
        QuestionWidget(
          questionText: Strings.whenWhereYouBorn,
          child: DatePickerWidget(
            onDateChanged: (val) => manager.setAnswer(Questions(birthDate: val)),
          ),
          icon: Assets.icons.calendar.svg(),
        ),

        // 4 - Height
        QuestionWidget(
          questionText: Strings.whatIsYourHeight,
          child: CustomTextField(
            metrics: ' sm',
            hintText: '- sm',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => manager.setAnswer(Questions(height: double.tryParse(val))),
          ),
          icon: Assets.icons.ruler.svg(),
        ),

        // 5 - Weight
        QuestionWidget(
          questionText: Strings.howManyKilograms,
          child: CustomTextField(
            metrics: ' kg',
            hintText: '- kg',
            keyboardType: TextInputType.number,
            onChanged: (val) => manager.setAnswer(Questions(weight: double.tryParse(val))),
          ),
          icon: Assets.icons.weight.svg(),
        ),

        // 6 - Target Weight
        QuestionWidget(
          questionText: Strings.weightChange,
          child: CustomTextField(
            hintText: '- kg',
            metrics: ' kg',
            keyboardType: TextInputType.number,
            onChanged: (val) => manager.setAnswer(Questions(targetWeight: double.tryParse(val))),
          ),
          icon: Assets.icons.weight.svg(),
        ),

        // 7 - Activity Hours
        QuestionWidget(
          questionText: Strings.activePerDay,
          child: PurposesWidget(
            onPurposeSelected: (val) => manager.setAnswer(Questions(activityHours: val.toString())),
            goals: activities,
          ),
          icon: Assets.icons.activity.svg(),
        ),
      ],
    );
  }
}
