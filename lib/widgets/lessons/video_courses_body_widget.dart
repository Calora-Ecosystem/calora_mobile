import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/task/task_parametrs_widget.dart';
import 'package:flutter/material.dart';

class VideoCoursesBodyWidget extends StatelessWidget {
  const VideoCoursesBodyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TaskParametersWidget(
            title: Row(
              children: [
                Strings.weightLossCourse.text(24, 32, 700),
                SizedBox(width: 8),
                Assets.icons.lock.svg(),
              ],
            ),
            parameters: [
              ParameterItem(name: 'Narxi', value: '1.300.000 so`m'),
              ParameterItem(name: 'Darslar soni', value: '10 ta'),
              ParameterItem(name: Strings.duration, value: '492 min'),
            ],
            bottomLabel: Strings.exercises,
            bottomCount: 10,
          ),
        ],
      ),
    );
  }
}
