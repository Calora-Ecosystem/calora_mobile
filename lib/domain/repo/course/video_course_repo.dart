import 'package:calora/domain/model/course/video_course_info.dart';

abstract class VideoCourseRepo {
  Future<CoursesInfo> getSlimmingCourses();
  Future<CoursesInfo> getBulkingCourses();
}
