import 'package:calora/data/api/course_api.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: CourseRepo)
class CourseRepoImpl implements CourseRepo {
  final CourseApi _courseApi;

  CourseRepoImpl(this._courseApi);

  @override
  Future<List<LessonInfo>> getLessons() {
    return Future.value(_lessons);
  }

  List<LessonInfo> _lessons = [
    LessonInfo(id: 1, duration: 8, calories: 150, level: 0.5, isCompleted: true, isLocked: false),
    LessonInfo(id: 2, duration: 8, calories: 150, level: 0.5, isLocked: false),
    LessonInfo(id: 3, duration: 8, calories: 150, level: 0.5, isLocked: false, isDayOff: true),
    LessonInfo(id: 4, duration: 8, calories: 150, level: 0.5, isLocked: false),
    LessonInfo(id: 5, duration: 8, calories: 150, level: 0.5, isLocked: true),
    LessonInfo(id: 6, duration: 8, calories: 150, level: 0.5, isLocked: true),
  ];
}
