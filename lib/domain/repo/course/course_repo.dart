import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart';

abstract class CourseRepo {
  Future<List<LessonInfo>> getLessons();

  Future<List<CourseRequest>> getCourse();

  Future<List<LessonRequest>> getLessonsById(int id);
}
