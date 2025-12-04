import 'dart:async';
import 'dart:ui';

import 'package:calora/widgets/progress/universal_progress_page/management/universal_progress_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@Injectable()
class UniversalProgressManager extends Manager<UniversalProgressState, UniversalProgressEffect> {
  Timer? _timer;

  UniversalProgressManager() : super(const UniversalProgressState());

  void startProgressAnimation({VoidCallback? onComplete}) {
    _timer?.cancel();

    const durationSeconds = 10; // o'zgartirish mumkin
    const ticksPerSecond = 60;
    final totalTicks = durationSeconds * ticksPerSecond;
    int currentTick = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ ticksPerSecond), (timer) {
      currentTick++;
      final progress = (currentTick / totalTicks).clamp(0.0, 1.0);

      emit(state.copyWith(progress: progress));

      if (progress >= 1.0) {
        timer.cancel();
        emit(state.copyWith(isCompleted: true));
        publish(const UniversalProgressEffect.completed());
        onComplete?.call();
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
