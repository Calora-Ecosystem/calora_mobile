import 'dart:async';
import 'dart:math';

import 'package:calora/common/gen/assets.gen.dart';
import 'package:calora/presentation/ai/ai/management/calora_ai_calculate_management.dart';
import 'package:flutter/animation.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@singleton
@Injectable()
class CaloraAiCalculateManager extends Manager<CaloraAiCalculateState, CaloraAiCalculateEffect> {
  Timer? _animationTimer;
  static const int _animationDurationSeconds = 10;
  static const int _ticksPerSecond = 60;
  final Random _random = Random();

  CaloraAiCalculateManager() : super(CaloraAiCalculateState.initial());

  void startProgressAnimation({VoidCallback? onComplete}) {
    _animationTimer?.cancel();

    final totalTicks = _animationDurationSeconds * _ticksPerSecond;
    int currentTick = 0;

    _animationTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ _ticksPerSecond), (timer) {
      currentTick++;
      final progress = (currentTick / totalTicks).clamp(0.0, 1.0);

      emit(state.copyWith(progressPercent: progress));

      if (progress >= 1.0) {
        timer.cancel();
        _generateRandomResults();
        onComplete?.call();
      }
    });
  }

  void _generateRandomResults() {
    final score = _random.nextInt(81) + 20;
    final items = [
      AnalysisItem(
        description: 'Yuzda toshmaalar bor - Jigarlangiz yoki oshqozoningizni tekshirting.',
        iconPath: Assets.icons.redUser.svg(),
        percentage: _random.nextInt(81) + 20,
        status: _getRandomStatus(),
      ),
      AnalysisItem(
        description: "Ko'z osti qoraygan - Uyqu sifatini yaxshilang.",
        iconPath: Assets.icons.moon.svg(),
        percentage: _random.nextInt(81) + 20,
        status: _getRandomStatus(),
      ),
      AnalysisItem(
        description: "O'rtacha - Ko'proq suv iching va faol bo'ling.",
        iconPath: Assets.icons.energy.svg(),
        percentage: _random.nextInt(81) + 20,
        status: _getRandomStatus(),
      ),
      AnalysisItem(
        description: "Yuqori - dam olish va meditatsiya qiling.",
        iconPath: Assets.icons.favourite.svg(),
        percentage: _random.nextInt(81) + 20,
        status: _getRandomStatus(),
      ),
      AnalysisItem(
        description: "Yetarli emas - Kechqurun ertaroq uxlashni odat qiling!",
        iconPath: Assets.icons.moon.svg(),
        percentage: _random.nextInt(81) + 20,
        status: _getRandomStatus(),
      ),
    ];

    emit(state.copyWith(finalScore: score, isCompleted: true, analysisItems: items));
  }

  String _getRandomStatus() {
    final statuses = ['Normal', 'Tekshlirish', 'Tekshirildi'];
    return statuses[_random.nextInt(statuses.length)];
  }

  void completeAnalysis() {
    publish(const CaloraAiCalculateEffect.analysisComplete());
  }

  @override
  Future<void> close() {
    _animationTimer?.cancel();
    return super.close();
  }
}
