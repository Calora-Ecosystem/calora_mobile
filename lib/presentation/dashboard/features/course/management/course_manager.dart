import 'package:calora/common/base/gender_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/presentation/dashboard/features/course/management/course_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CourseManager extends Manager<CourseState, CourseEffect> {
  CourseManager() : super(const CourseState());

  final GenderStore _genderStore = getIt<GenderStore>();

  Future<void> loadGender() async {
    final gender = await _genderStore();
    emit(state.copyWith(gender: gender));
  }
}
