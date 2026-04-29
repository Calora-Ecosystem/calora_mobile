import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/model/profile/profile_request.dart';
import 'package:calora/domain/model/questions/questions_request.dart';
import 'package:calora/domain/model/workout/workout_request.dart';
import 'package:calora/domain/repo/course/course_repo.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:calora/presentation/tasks/management/tasks_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class TasksManager extends Manager<TasksState, TasksEffect> {
  final CourseRepo _courseRepo;
  final QuestionsRepo _questionsRepo;

  TasksManager(this._courseRepo, this._questionsRepo) : super(const TasksState());

  void setLevel(int index) {
    emit(state.copyWith(levelIndex: index));
  }

  void initWorkout(WorkoutRequest workout) {
    emit(state.copyWith(workout: workout));
  }

  void getExercises(int id) {
    final levelText = _levelTextFromIndex(state.levelIndex);

    _courseRepo
        .getExercisesByWorkoutId(id, levelText)
        .handle(
          onStart: () => emit(
            state.copyWith(isLoading: true),
          ),
          onData: (data) => emit(state.copyWith(exercises: data, isLoading: false)),
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> changeActivityLevel(int courseId, int index, int currentOrder) async {
    final levelText = _levelTextFromIndex(index);
    emit(state.copyWith(levelIndex: index, isLoading: true));
    await profileStore.updateActivityLevel(levelText);
    await refreshActivityLevel(index);
    _courseRepo
        .getWorkout(courseId, levelText)
        .handle(
          onData: (workouts) {
            final workout = workouts.firstWhere(
              (w) => w.order == currentOrder,
              orElse: () => workouts.first,
            );
            emit(state.copyWith(workout: workout));
            getExercises(workout.id);
          },
          onError: (error) => emit(state.copyWith(isLoading: false)),
        );
  }

  Future<void> refreshActivityLevel(int levelIndex) async {
    final profile = await profileStore.getProfile();
    final levelText = _levelTextFromIndex(levelIndex);

    String? purposeApi = profile.goal;
    if (purposeApi == '0' || purposeApi == 'WeightLoss')
      purposeApi = 'WeightLoss';
    else if (purposeApi == '1' || purposeApi == 'SaveCurrent')
      purposeApi = 'SaveCurrent';
    else if (purposeApi == '2' || purposeApi == 'MuscleDevelopment')
      purposeApi = 'MuscleDevelopment';

    final tWeight = (profile.targetWeight ?? 0) == 0 ? profile.weight : profile.targetWeight;

    final request = QuestionsRequest(
      name: profile.name,
      gender: profile.gender,
      purpose: purposeApi,
      birthDate: profile.birthDay != null ? DateTime.tryParse(profile.birthDay!) : null,
      height: profile.height,
      weight: profile.weight,
      targetWeight: tWeight,
      bmi: profile.bmi,
      activityLevel: levelText,
      language: 'Uzbek',
      physicalActivity: profile.physicalActivity,
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
}
