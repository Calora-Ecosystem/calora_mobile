import 'dart:math';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/model/questions/questions.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:calora/presentation/questions/questions/management/questions_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class QuestionsManager extends Manager<QuestionsState, QuestionsEffect> {
  final QuestionsRepo _repo;

  QuestionsManager(this._repo) : super(const QuestionsState()) {
    _hydrateFromProfile();
  }

  Future<void> _hydrateFromProfile() async {
    final stored = await getIt<ProfileStore>().getProfile();
    final hasName = (stored.name ?? '').trim().isNotEmpty;
    if (!hasName) return;
    emit(
      state.copyWith(
        answers: (state.answers ?? const Questions()).copyWith(
          name: stored.name,
        ),
      ),
    );
  }

  void setAnswer(Questions model) {
    final updated =
        state.answers?.copyWith(
          name: model.name ?? state.answers?.name,
          entryWeight: model.weight ?? state.answers?.weight,
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

    final tWeight = (profile.targetWeight ?? 0) == 0 ? profile.weight : profile.targetWeight;

    final request = QuestionsRequest(
      name: profile.name,
      gender: profile.gender?.toApi(),
      purpose: mapPurpose(profile.purposeIds?.first ?? 0).toApi(),
      birthDate: profile.birthDate,
      height: profile.height,
      weight: profile.weight,
      targetWeight: tWeight,
      activityLevel: profile.activityHours ?? ActivityLevelEnum.Medium.toApi(),
      bmi: bmi,
      language: 'Uzbek',
      physicalActivity: 'Healthy',
    );

    final profileRequest = ProfileRequest(
      name: profile.name,
      gender: profile.gender?.toApi(),
      birthDay: profile.birthDate?.toIso8601String(),
      height: profile.height,
      weight: profile.weight,
      targetWeight: tWeight,
      bmi: bmi,
      goal: mapPurpose(profile.purposeIds?.first ?? 0).toApi(),
      activityLevel: profile.activityHours ?? ActivityLevelEnum.Medium.toApi(),
      physicalActivity: 'Healthy',
      language: 'Uzbek',
    );

    getIt<ProfileStore>().set(profileRequest);
    getIt<ProfileStore>().setGender(profile.gender?.toApi() ?? '');

    _repo
        .sendTargetWeight(
          NormsRequest(metric: 'Weight', value: profile.targetWeight ?? 0),
        )
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
            publish(
              const QuestionsEffect.withType(QuestionsEffectType.success),
            );
          },
        );
  }

  PurposeEnum mapPurpose(int value) {
    if (value == 0) return PurposeEnum.WeightLoss;
    if (value == 1) return PurposeEnum.SaveCurrent;
    return PurposeEnum.MuscleDevelopment;
  }
}
