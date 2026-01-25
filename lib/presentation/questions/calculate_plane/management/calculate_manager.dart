import 'dart:async';

import 'package:calora/domain/repo/questions/questions_repo.dart';
import 'package:calora/presentation/questions/calculate_plane/management/calculate_management.dart';
import 'package:flutter/animation.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@singleton
@Injectable()
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
  }) async {
    _apiProgressTimer?.cancel();

    emit(state.copyWith(progressPercent: 0));

    _apiProgressTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final p = state.progressPercent;

      if (p < 0.95) {
        final inc = (0.95 - p) * 0.08;
        final next = (p + inc).clamp(0.0, 0.95);
        emit(state.copyWith(progressPercent: next));
      }
    });

    try {
      await apiCall();

      _apiProgressTimer?.cancel();

      emit(state.copyWith(progressPercent: 1.0));

      onComplete?.call();
      publish(const CalculateEffect.navigateNext());
    } catch (e) {
      _apiProgressTimer?.cancel();

      publish(CalculateEffect.error(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _animationTimer?.cancel();
    return super.close();
  }
}
