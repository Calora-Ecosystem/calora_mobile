import 'package:calora/domain/model/course/course_request.dart';
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/model/workout/workout_request.dart';

abstract class CourseRepo {
  Future<List<CourseRequest>> getCourse();

  Future<List<LessonRequest>> getLessonsById(int id);

  Future<List<WorkoutRequest>> getWorkout(int courseId, String level);

  Future<void> updateVideoCourseFinished(int id);

  Future<List<ExercisesRequest>> getExercisesByWorkoutId(int id);

  Future<void> refreshActivityLevel(QuestionsRequest answer);

  Future<void> finishedExercises(int id);
}
