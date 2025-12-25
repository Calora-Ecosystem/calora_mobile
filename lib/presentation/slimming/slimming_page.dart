import 'package:auto_route/annotations.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

import 'package:calora/presentation/slimming/management/slimming_management.dart';
import 'package:calora/presentation/slimming/management/slimming_manager.dart';

@RoutePage()
class SlimmingPage extends Managed<SlimmingManager, SlimmingState, SlimmingEffect> {
  const SlimmingPage({super.key});

  @override
  void init(BuildContext context, SlimmingManager manager) {
    manager.getVideoCourses();
    super.init(context, manager);
  }

  @override
  Widget builder(BuildContext context, SlimmingManager manager, SlimmingState state) {
    return Scaffold(
      backgroundColor: context.colors.accentDisabled,
      // body: VideoCoursesBodyWidget(
      //   type: CoursesType.slimming,
      //   course:
      //       state.videoCourse ??
      //       CoursesInfo(videoCourses: [], name: '', price: '', duration: Duration()),
      // ),
    );
  }
}
