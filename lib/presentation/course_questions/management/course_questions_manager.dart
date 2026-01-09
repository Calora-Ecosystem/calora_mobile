import 'package:calora/presentation/course_questions/management/course_questions_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CourseQuestionsManager
    extends Manager<CourseQuestionsState, CourseQuestionsEffect> {
  CourseQuestionsManager() : super(const CourseQuestionsState());

  void next() {
    emit(state.copyWith(currentIndex: state.currentIndex + 1));
  }

  void back() {
    if (state.currentIndex > 0) {
      emit(state.copyWith(currentIndex: state.currentIndex - 1));
    }
  }

  void finish() {}

  void setAnswer({int? condition, int? activityTime, String? trainingTime}) {
    emit(
      state.copyWith(
        courseQuestionsInfo: state.courseQuestionsInfo.copyWith(
          condition: condition ?? state.courseQuestionsInfo.condition,
          activityTime: activityTime ?? state.courseQuestionsInfo.activityTime,
          trainingTime: trainingTime ?? state.courseQuestionsInfo.trainingTime,
        ),
      ),
    );
  }

  bool get isAnswerProvided {
    final info = state.courseQuestionsInfo;
    switch (state.currentIndex) {
      case 0:
        return info.condition != null;
      case 1:
        return info.activityTime != null;
      case 2:
        return info.trainingTime != null && info.trainingTime!.isNotEmpty;
      default:
        return false;
    }
  }
}
