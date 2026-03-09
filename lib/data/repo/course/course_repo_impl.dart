import 'package:calora/common/base/profile_store.dart';
import 'package:calora/data/api/course_api.dart';
import 'package:calora/data/api/profile_api.dart';
import 'package:calora/data/api/questions_api.dart';
import 'package:calora/domain/model/course/course_request.dart' show CourseRequest;
import 'package:calora/domain/model/course/exercise/exercises_request.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: CourseRepo)
class CourseRepoImpl implements CourseRepo {
  final CourseApi _courseApi;
  final QuestionsApi _questionsApi;
  final ProfileApi _profileApi;

  CourseRepoImpl(this._courseApi, this._questionsApi, this._profileApi);

  @override
  Future<List<CourseRequest>> getCourse() async {
    final profile = await profileStore.getProfile();
    final response = await _courseApi.getCourse(profile.gender ?? Gender.Male.name);
    final data = response.data;
    final List<dynamic> content = data['content'] ?? [];
    return content.map((item) => CourseRequest.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LessonRequest>> getLessonsById(int id) async {
    final result = await _courseApi.getLessonsById(id);
    final data = result.data;
    final List<dynamic> content = data['content'] ?? [];
    return content.map((item) => LessonRequest.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<WorkoutRequest>> getWorkout(int courseId, String level) async {
    final result = await _courseApi.getLessonById(courseId, level);
    final data = result.data;
    final List<dynamic> content = data['content'] ?? [];
    return content.map((item) => WorkoutRequest.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> updateVideoCourseFinished(int id) async {
    await _courseApi.updateVideoCourseFinished(id);
  }

  @override
  Future<List<ExercisesRequest>> getExercisesByWorkoutId(int id) async {
    final result = await _courseApi.getExercisesByWorkoutId(id);
    final data = result.data;
    final List<dynamic> content = data['content'] ?? [];
    return content.map((item) => ExercisesRequest.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> refreshActivityLevel(QuestionsRequest answer) async {
    await _questionsApi.sendAnswers(answer);
  }

  @override
  Future<void> finishedExercises(int id) async {
    await _courseApi.finishedExercises(id);
  }

  @override
  Future<void> finishWorkout(int id) async {
    await _courseApi.finishWorkout(id);
  }
}
