import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/course/video_course_info.dart';
import 'package:calora/domain/repo/course/video_course_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: VideoCourseRepo)
class VideoCourseRepoImpl implements VideoCourseRepo {
  @override
  Future<CoursesInfo> getSlimmingCourses() {
    return Future.value(weightLossCourse);
  }

  Future<CoursesInfo> getBulkingCourses() {
    return Future.value(massGainCourse);
  }
}

CoursesInfo weightLossCourse = CoursesInfo(
  videoCourses: videoCourses,
  name: Strings.weightLossCourse,
  duration: Duration(hours: 1, minutes: 12),
  price: '1.300.000 so`m',
);

CoursesInfo massGainCourse = CoursesInfo(
  videoCourses: videoCourses,
  name: Strings.massGainCourse,
  duration: Duration(hours: 1, minutes: 12),
  price: '1.500.000 so`m',
);

List<VideoCourseInfo> videoCourses = [
  VideoCourseInfo(name: 'Video Course 1', duration: Duration(hours: 1, minutes: 12)),
  VideoCourseInfo(name: 'Video Course 2', duration: Duration(hours: 2, minutes: 7)),
  VideoCourseInfo(name: 'Video Course 3', duration: Duration(hours: 3)),
  VideoCourseInfo(name: 'Video Course 4', duration: Duration(hours: 4)),
  VideoCourseInfo(name: 'Video Course 5', duration: Duration(hours: 5)),
  VideoCourseInfo(name: 'Video Course 6', duration: Duration(hours: 6)),
  VideoCourseInfo(name: 'Video Course 7', duration: Duration(hours: 7)),
  VideoCourseInfo(name: 'Video Course 8', duration: Duration(hours: 8)),
  VideoCourseInfo(name: 'Video Course 9', duration: Duration(hours: 9)),
  VideoCourseInfo(name: 'Video Course 10', duration: Duration(hours: 10)),
];
