import 'package:auto_route/auto_route.dart';
import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/leave/leave_page.dart';
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
            GestureDetector(
              onTap: () => _showLeaveBottomSheet(context),
              child: Assets.icons.arrowLeft.svg(),
            ),
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
                width: double.infinity,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildButton(context: context, icon: Assets.icons.pause.svg(), onTap: () {}),
                    Column(
                      children: [
                        '00:${taskInfo.duration}'.text(32, 40, 700),
                        Strings.getReady.text(16, 20, 500).c(context.colors.accentSub),
                      ],
                    ),
                    _buildButton(
                      context: context,
                      icon: Assets.icons.arrowRight.svg(),
                      onTap: () {},
                    ),
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

  void _showLeaveBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      backgroundColor: context.colors.white,
      builder: (context) {
        return LeavePage();
      },
    );
  }
}
