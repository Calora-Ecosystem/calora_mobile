import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:calora/presentation/lessons/management/lessons_management.dart';
import 'package:injectable/injectable.dart' show injectable;
import 'package:management/management.dart';

@injectable
class LessonsManager extends Manager<LessonsState, LessonsEffect> {
  final CourseRepo _courseRepo;
  final QuestionsRepo _questionsRepo;

  LessonsManager(this._courseRepo, this._questionsRepo) : super(const LessonsState());

  void setLevel(int index) {
    emit(state.copyWith(levelIndex: index));
  }

  Future<void> changeActivityLevel(int courseId, int index) async {
    final levelText = _levelTextFromIndex(index);
    emit(state.copyWith(levelIndex: index, isLoading: true));

    // Update profile local store
    await profileStore.updateActivityLevel(levelText);

    // Refresh activity level on server
    await refreshActivityLevel(index);

    // Fetch workouts for the new level
    _courseRepo.getWorkout(courseId, levelText).handle(
          onData: (workouts) => emit(state.copyWith(workouts: workouts, isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  void getWorkout(int id) {
    _courseRepo
        .getWorkout(id, _levelTextFromIndex(state.levelIndex))
        .handle(
          onStart: () => emit(state.copyWith(isLoading: true)),
          onData: (workouts) => emit(state.copyWith(workouts: workouts, isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> loadActivityLevel() async {
    final profile = await profileStore.getProfile();
    if (profile.activityLevel is String) {
      emit(state.copyWith(levelIndex: levelIndexFromText(profile.activityLevel)));
    }
  }

  Future<void> refreshActivityLevel(int levelIndex) async {
    final profile = await profileStore.getProfile();
    final levelText = _levelTextFromIndex(levelIndex);

    // Purpose mappingni onboarding bilan bir xil qilamiz
    String? purposeApi = profile.goal;
    if (purposeApi == '0' || purposeApi == 'WeightLoss') purposeApi = 'WeightLoss';
    else if (purposeApi == '1' || purposeApi == 'SaveCurrent') purposeApi = 'SaveCurrent';
    else if (purposeApi == '2' || purposeApi == 'MuscleDevelopment') purposeApi = 'MuscleDevelopment';

    final request = QuestionsRequest(
      name: profile.name,
      gender: profile.gender,
      purpose: purposeApi,
      birthDate: profile.birthDay != null ? DateTime.tryParse(profile.birthDay!) : null,
      height: profile.height,
      weight: profile.weight,
      targetWeight: profile.targetWeight,
      bmi: profile.bmi,
      activityLevel: levelText,
      language: 'Uzbek',
      physicalActivity: profile.physicalActivity ?? 'Healthy',
    );
    await _questionsRepo.sendAnswers(request);
  }

  String _levelTextFromIndex(int index) {
    const levels = [
      'Minimal',
      'Less',
      'Medium',
      'High',
      'Maximal',
    ];

    if (index < 0 || index >= levels.length) {
      return 'Medium';
    }

    return levels[index];
  }

  int levelIndexFromText(String text) {
    const levels = [
      'Minimal',
      'Less',
      'Medium',
      'High',
      'Maximal',
    ];

    return levels.indexOf(text);
  }
}
