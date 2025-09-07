import 'dart:math';

import 'package:calora/domain/model/questions/questions.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import '../../../../domain/repo/questions/questions_repo.dart';
import 'questions_management.dart';

@injectable
class QuestionsManager extends Manager<QuestionsState, QuestionsEffect> {
  final QuestionsRepo _repo;
  QuestionsManager(this._repo) : super(QuestionsState());

  void setAnswer({
    String? name,
    String? gender,
    List<int>? purposeIds,
    DateTime? birthDate,
    double? height,
    double? weight,
    double? bmi,
    double? targetWeight,
    String? activityHours,
    String? photo,
    String? language,
  }) {
    final currentProfile = state.answers ?? QuestionsModel();

    final updatedProfile = currentProfile.copyWith(
      name: name ?? currentProfile.name,
      gender: gender ?? currentProfile.gender,
      purposeIds: purposeIds ?? currentProfile.purposeIds,
      birthDate: birthDate ?? currentProfile.birthDate,
      height: height ?? currentProfile.height,
      weight: weight ?? currentProfile.weight,
      targetWeight: targetWeight ?? currentProfile.targetWeight,
      activityHours: activityHours ?? currentProfile.activityHours,
    );

    emit(state.copyWith(answers: updatedProfile));
  }

  bool getButtonStatus() {
    switch (state.currentIndex) {
      case 0:
        // log("${state.answers?.name.trim()}");
        return state.answers?.name?.trim().isNotEmpty ?? false;
      case 1:
        return state.answers?.gender?.trim().isNotEmpty ?? false;
      case 2:
        return state.answers?.purposeIds?.isNotEmpty ?? false;
      case 3:
        return state.answers?.birthDate != null;
      case 4:
        return state.answers?.height != null;
      case 5:
        return state.answers?.weight != null;
      case 6:
        return state.answers?.targetWeight != null;
      case 7:
        return state.answers?.activityHours?.trim().isNotEmpty ?? false;
    }
    return false;
  }

  void next() {
    emit(state.copyWith(currentIndex: state.currentIndex + 1));
  }

  void back() {
    if (state.currentIndex > 0) {
      emit(state.copyWith(currentIndex: state.currentIndex - 1));
    }
  }

  Future<void> finish() async {
    var profile = state.answers;
    if (profile == null) {
      emit(state.copyWith());
      return;
    }
    if (profile.height == null && profile.weight == null) {
      final bmi = profile.weight! / pow(profile.height!, 2);
      await _repo.sendAnswers(profile.copyWith(bmi: bmi));
    }
    print("Final Profile: ${profile}");
  }
}
