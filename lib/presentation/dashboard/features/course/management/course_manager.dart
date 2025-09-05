import 'package:calora/presentation/dashboard/features/course/management/course_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CourseManager extends Manager<CourseState, CourseEffect> {

  CourseManager() : super(const CourseState());

}