import 'dart:async';

import 'package:calora/common/base/profile_store.dart';
import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:calora/presentation/questions/calculate_plane/management/calculate_management.dart';
import 'package:flutter/animation.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class CalculateManager extends Manager<CalculateState, CalculateEffect> {
  final QuestionsRepo questionsRepo;
  Timer? _animationTimer;
  static const int _animationDurationSeconds = 10;
  static const int _ticksPerSecond = 60;

  CalculateManager(this.questionsRepo) : super(CalculateState.initial());

  void resetProgress() {
    _apiProgressTimer?.cancel();
    _animationTimer?.cancel();
    emit(state.copyWith(progressPercent: 0.0));
  }

  Future<void> getProfile() async {
    final profile = await profileStore.getProfile();
    final bool showBmiProgress = (profile.goal ?? '').trim() != 'SaveCurrent';
    emit(state.copyWith(startValue: profile.weight ?? 0, endValue: profile.targetWeight ?? 0));
  }

  void getDailyGoals() async {
    await questionsRepo.getDailyGoals().handle(
      onStart: () => emit(state.copyWith(isLoading: true)),
      onData: (goals) => emit(state.copyWith(dailyGoals: goals, isLoading: false)),
      onError: (error) {
        emit(state.copyWith(isLoading: false));
        publish(CalculateEffect.error(error.toString()));
      },
    );
  }

  void startProgressAnimation({VoidCallback? onComplete}) {
    resetProgress();
    _animationTimer?.cancel();

    final totalTicks = _animationDurationSeconds * _ticksPerSecond;
    int currentTick = 0;

    _animationTimer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ _ticksPerSecond),
      (timer) {
        currentTick++;
        final progress = (currentTick / totalTicks).clamp(0.0, 1.0);

        emit(state.copyWith(progressPercent: progress));

        if (progress >= 1.0) {
          timer.cancel();
          onComplete?.call();
        }
      },
    );
  }

  Timer? _apiProgressTimer;

  void startProgressWithApi({
    required Future<void> Function() apiCall,
    VoidCallback? onComplete,
  }) {
    _apiProgressTimer?.cancel();
    emit(state.copyWith(progressPercent: 0));

    // Keep the "preparing your program" loader on screen for at least this
    // long, even when the API responds almost instantly, so it doesn't flash
    // past the user. The ring completes only once BOTH the minimum time has
    // elapsed and the API has returned.
    const minDuration = Duration(seconds: _animationDurationSeconds);
    final startedAt = DateTime.now();

    bool apiCompleted = false;
    Object? apiError;
    apiCall().then((_) {
      apiCompleted = true;
    }).catchError((Object e) {
      apiError = e;
    });

    _apiProgressTimer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ _ticksPerSecond),
      (timer) {
        if (apiError != null) {
          timer.cancel();
          publish(CalculateEffect.error(apiError.toString()));
          return;
        }

        final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
        final timeFraction =
            (elapsedMs / minDuration.inMilliseconds).clamp(0.0, 1.0);

        if (timeFraction >= 1.0 && apiCompleted) {
          timer.cancel();
          emit(state.copyWith(progressPercent: 1.0));
          onComplete?.call();
          publish(const CalculateEffect.navigateNext());
          return;
        }

        // Ease toward 100% once the API is done; otherwise hold below 95% so
        // the ring keeps spinning until the response arrives.
        final progress =
            apiCompleted ? timeFraction : (timeFraction * 0.95);
        emit(state.copyWith(progressPercent: progress));
      },
    );
  }

  @override
  Future<void> close() {
    _animationTimer?.cancel();
    return super.close();
  }
}
