import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

@RoutePage()
class TaskPage extends StatelessWidget {
  final TaskInfo taskInfo;
  const TaskPage({super.key, required this.taskInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        leading: Row(
          children: [
            SizedBox(width: 16),
            GestureDetector(onTap: () => context.router.pop(), child: Assets.icons.arrowLeft.svg()),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 70, vertical: 30),
                color: context.colors.backgroundElevation,
                child: Assets.images.task.image(),
              ),
              const SizedBox(height: 20),
              taskInfo.descriptionTitle.text(20, 24, 700).c(context.colors.textStrong),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.backgroundElevation,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // _buildButton(context: context, icon: Assets.icons..svg(), onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: icon,
      ),
    );
  }
}
