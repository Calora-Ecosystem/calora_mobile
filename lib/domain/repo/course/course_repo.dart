import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:calora/domain/model/workout/workout_request.dart';

abstract class CourseRepo {
  Future<List<CourseRequest>> getCourse();

  Future<List<LessonRequest>> getLessonsById(int id);

  Future<List<WorkoutRequest>> getWorkout();

  Future<void> updateVideoCourseFinished(int id);
}
