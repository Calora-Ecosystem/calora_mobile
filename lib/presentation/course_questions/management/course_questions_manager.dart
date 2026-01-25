import 'dart:math';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/questions/questions.dart' show ActivityLevelEnum;
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/model/reminder/reminder_request.dart';
import 'package:calora/domain/repo/notification/notification_repo.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:calora/presentation/course_questions/management/course_questions_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CourseQuestionsManager extends Manager<CourseQuestionsState, CourseQuestionsEffect> {
  final QuestionsRepo _questionsRepo;
  final NotificationRepo _notificationRepo;

  CourseQuestionsManager(this._questionsRepo, this._notificationRepo) : super(const CourseQuestionsState());

  void next() {
    emit(state.copyWith(currentIndex: state.currentIndex + 1));
  }

  void back() {
    if (state.currentIndex > 0) {
      emit(state.copyWith(currentIndex: state.currentIndex - 1));
    }
  }

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

  Future<void> finish() async {
    final info = state.courseQuestionsInfo;

    emit(state.copyWith());

    final profileStore = getIt<ProfileStore>();
    final saved = await profileStore.getProfile();

    final double? bmi = (saved.height != null && saved.weight != null && saved.height! > 0)
        ? saved.weight! / pow(saved.height! / 100, 2)
        : saved.bmi;

    final activityLevelApi = _activityLevelFromId(info.activityTime);

    final physicalActivity = info.condition?.toString();

    await profileStore.updateProfile(
      bmi: bmi,
      activityLevel: activityLevelApi ?? saved.activityLevel,
      physicalActivity: physicalActivity,
    );
    final request = QuestionsRequest(
      name: saved.name,
      gender: saved.gender,
      purpose: saved.goal,
      birthDate: DateTime.tryParse(saved.birthDay ?? ''),
      height: saved.height,
      weight: saved.weight,
      targetWeight: saved.targetWeight,
      bmi: bmi,
      activityLevel: activityLevelApi ?? Strings.averageActivity,
      language: 'Uzbek',
      physicalActivity: physicalActivity,
    );

    _questionsRepo.sendAnswers(request);
    updateNotification(_formatTimeToApi(state.courseQuestionsInfo.trainingTime) ?? '00:00:00');
  }

  void updateNotification(String time) {
    _notificationRepo.updateReminder(ReminderRequest(menu: 'Breakfast', time: time, type: 'DailyChallenge'));
  }

  String? _activityLevelFromId(int? id) {
    if (id == null) return null;

    if (id < 0 || id >= ActivityLevelEnum.values.length) {
      return ActivityLevelEnum.Unknown.toApi();
    }
    return ActivityLevelEnum.values[id].toApi();
  }

  String? _formatTimeToApi(String? time) {
    if (time == null) return null;

    final t = time.trim();

    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(t)) {
      return t;
    }
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(t)) {
      return '$t:00';
    }

    return null;
  }
}
