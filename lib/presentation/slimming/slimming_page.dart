import 'package:auto_route/annotations.dart';
import 'package:calora/common/base/gender_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/extensions/bottom_sheet.dart';
import 'package:calora/domain/model/course/video_course_info.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/widgets/app_bar/courses_app_bar.dart';
import 'package:calora/widgets/info/course_info_widget.dart';
import 'package:calora/widgets/lessons/video_courses_body_widget.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'management/slimming_management.dart';
import 'management/slimming_manager.dart';

@RoutePage()
class SlimmingPage extends Managed<SlimmingManager, SlimmingState, SlimmingEffect> {
  final gender = getIt<GenderStore>().call();

  @override
  void init(BuildContext context, SlimmingManager manager) {
    manager.getVideoCourses();
    super.init(context, manager);
  }

  @override
  Widget builder(BuildContext context, SlimmingManager manager, SlimmingState state) {
    return Scaffold(
      backgroundColor: context.colors.accentDisabled,
      body: Stack(
        children: [
          CoursesAppBar(
            openInfoSheet: () => openInfoSheet(context),
            gender: gender,
            type: CoursesType.bulking,
          ),
          Column(
            children: [
              SizedBox(height: 230),
              Expanded(
                child: VideoCoursesBodyWidget(
                  course:
                      state.videoCourse ??
                      CoursesInfo(videoCourses: [], name: '', price: '', duration: Duration()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void openInfoSheet(BuildContext context) {
    context.showAppBottomSheet(child: CourseInfoWidget(), backgroundColor: context.colors.white);
  }
}
