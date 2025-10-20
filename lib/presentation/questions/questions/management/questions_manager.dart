import 'dart:math';

import 'package:calora/common/base/gender_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/profile/profile.dart';
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

  void finish() {
    final profile = state.answers;
    if (profile == null) return;

    emit(state.copyWith(isLoading: true));

    final bmi = (profile.height != null && profile.weight != null)
        ? profile.weight! / pow(profile.height! / 100, 2)
        : null;

    final request = QuestionsRequest(
      name: profile.name,
      gender: profile.gender?.name,
      purposeIds: profile.purposeIds,
      birthDate: profile.birthDate,
      height: profile.height,
      weight: profile.weight,
      targetWeight: profile.targetWeight,
      activityHours: profile.activityHours,
      bmi: bmi,
      language: 'Uzbek',
    );
    getIt<GenderStore>().set(profile.gender ?? Gender.Male);
    _repo
        .sendTargetWeight(NormsRequest(metric: 'Weight', value: profile.targetWeight ?? 0))
        .handle(
          onStart: () {
            emit(state.copyWith(isLoading: true));
          },
          onError: (error) {
            emit(state.copyWith(isLoading: false));
            publish(const QuestionsEffect.withType(QuestionsEffectType.error));
          },
          onDone: () {},
        );
    _repo
        .sendAnswers(request)
        .handle(
          onStart: () {
            emit(state.copyWith(isLoading: true));
          },
          onData: (_) {
            emit(state.copyWith(isLoading: false));
          },
          onError: (error) {
            emit(state.copyWith(isLoading: false));
            publish(const QuestionsEffect.withType(QuestionsEffectType.error));
          },
          onDone: () {
            publish(const QuestionsEffect.withType(QuestionsEffectType.success));
          },
        );
  }
}
