import 'dart:math';

import 'package:calora/domain/model/questions/questions.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/repo/auth/auth_repo.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

import 'questions_management.dart';

@injectable
class QuestionsManager extends Manager<QuestionsState, QuestionsEffect> {
  final QuestionsRepo _repo;
  final AuthRepo _authRepo;

  QuestionsManager(this._repo, this._authRepo) : super(const QuestionsState());

  void setAnswer(Questions model) {
    final updated =
        state.answers?.copyWith(
          name: model.name ?? state.answers?.name,
          gender: model.gender ?? state.answers?.gender,
          purposeIds: model.purposeIds ?? state.answers?.purposeIds,
          birthDate: model.birthDate ?? state.answers?.birthDate,
          height: model.height ?? state.answers?.height,
          weight: model.weight ?? state.answers?.weight,
          targetWeight: model.targetWeight ?? state.answers?.targetWeight,
          activityHours: model.activityHours ?? state.answers?.activityHours,
        ) ??
        model;
    emit(state.copyWith(answers: updated));
  }

  void next() {
    emit(state.copyWith(currentIndex: state.currentIndex + 1));
  }

  void back() {
    if (state.currentIndex > 0) {
      emit(state.copyWith(currentIndex: state.currentIndex - 1));
    }
  }

  Future<bool> finish() async {
    final profile = state.answers;
    if (profile == null) return false;

    emit(state.copyWith(isLoading: true));

    final bmi = (profile.height != null && profile.weight != null)
        ? profile.weight! / pow(profile.height! / 100, 2)
        : null;

    final request = QuestionsRequest(
      name: profile.name,
      gender: profile.gender,
      purposeIds: profile.purposeIds,
      birthDate: profile.birthDate,
      height: profile.height,
      weight: profile.weight,
      targetWeight: profile.targetWeight,
      activityHours: profile.activityHours,
      bmi: bmi,
      language: 'Uzbek',
    );

    bool success = false;

    await _repo
        .sendAnswers(request)
        .handle(
          onStart: () {},
          onData: (_) {
            success = true;
          },
          onError: (error) {
            success = false;
          },
          onDone: () {},
        );
    emit(state.copyWith(isLoading: false));
    return success;
  }

  Future<bool> register(String email) async {
    final profile = state.answers;
    if (profile == null) return false;
    emit(state.copyWith(isLoading: true));
    bool success = false;
    await _authRepo
        .register(email, profile.name!)
        .handle(
          onStart: () {},
          onData: (verification) {
            success = true;
            publish(QuestionsEffect.navigateToVerify(verification));
          },
          onError: (error) {
            success = false;
          },
          onDone: () {},
        );
    emit(state.copyWith(isLoading: false));
    return success;
  }
}
