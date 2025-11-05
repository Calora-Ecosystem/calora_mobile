import 'package:auto_route/annotations.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:calora/presentation/bulking/management/bulking_management.dart';
import 'package:calora/presentation/bulking/management/bulking_manager.dart';
import 'package:flutter/material.dart';
import 'package:management/management.dart';

@RoutePage()
class BulkingPage extends Managed<BulkingManager, BulkingState, BulkingEffect> {
  @override
  void init(BuildContext context, BulkingManager manager) {
    manager.getVideoCourses();
    super.init(context, manager);
  }

  @override
  Widget builder(BuildContext context, BulkingManager manager, BulkingState state) {
    return Scaffold(
      backgroundColor: context.colors.accentDisabled,
      // body: VideoCoursesBodyWidget(
      //   type: CoursesType.bulking,
      //   course:
      //       state.videoCourse ??
      //       CoursesInfo(videoCourses: [], name: '', price: '', duration: Duration()),
      // ),
    );
  }
}
