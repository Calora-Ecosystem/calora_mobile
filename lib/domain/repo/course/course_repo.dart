import 'package:calora/domain/model/lesson/lesson_info.dart';

abstract class CourseRepo {
  Future<List<LessonInfo>> getLessons();
}
