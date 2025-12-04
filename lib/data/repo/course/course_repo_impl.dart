import 'package:calora/common/base/profile_store.dart';
import 'package:calora/data/api/course_api.dart';
import 'package:calora/domain/model/lesson/lesson_info.dart';
import 'package:calora/domain/model/lesson/lesson_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/model/course/course_request.dart' show CourseRequest;

@Injectable(as: CourseRepo)
class CourseRepoImpl implements CourseRepo {
  final CourseApi _courseApi;

  CourseRepoImpl(this._courseApi);

  @override
  Future<List<LessonInfo>> getLessons() {
    return Future.value(_lessons);
  }

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

  List<LessonInfo> _lessons = [
    LessonInfo(
      id: 1,
      duration: 8,
      calories: 150,
      level: 0.5,
      isCompleted: true,
      isLocked: false,
      tasks: [
        TaskInfo(count: '00:30', title: 'Salom', isCompleted: true),
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '00:30', title: 'Ishlar qaleee'),
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '8', title: 'Salom'),
        TaskInfo(count: '8', title: 'Salom'),
      ],
    ),
    LessonInfo(
      id: 2,
      duration: 8,
      calories: 150,
      level: 0.5,
      isLocked: false,
      tasks: [
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '00:30', title: 'Ishlar qaleee'),
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '8', title: 'Salom'),
        TaskInfo(count: '8', title: 'Salom'),
      ],
    ),
    LessonInfo(id: 3, duration: 8, calories: 150, level: 0.5, isLocked: false, isDayOff: true, tasks: []),
    LessonInfo(
      id: 4,
      duration: 8,
      calories: 150,
      level: 0.5,
      isLocked: false,
      tasks: [
        TaskInfo(count: '00:30', title: 'Ishlar qaleee'),
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '8', title: 'Salom'),
        TaskInfo(count: '8', title: 'Salom'),
      ],
    ),
    LessonInfo(
      id: 5,
      duration: 8,
      calories: 150,
      level: 0.5,
      isLocked: true,
      tasks: [
        TaskInfo(count: '8', title: 'Ishlar qaleee', isCompleted: true),
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '8', title: 'Salom'),
        TaskInfo(count: '8', title: 'Salom'),
      ],
    ),
    LessonInfo(
      id: 6,
      duration: 8,
      calories: 150,
      level: 0.5,
      isLocked: true,
      tasks: [
        TaskInfo(count: '8', title: 'Salom'),
        TaskInfo(count: '00:30', title: 'Salom'),
        TaskInfo(count: '8', title: 'Ishlar qaleee'),
        TaskInfo(count: '8', title: 'Salom'),
      ],
    ),
  ];
}
