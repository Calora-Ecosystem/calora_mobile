import 'dart:async';
import 'dart:ui';

import 'package:calora/widgets/progress/universal_progress_page/management/universal_progress_management.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@Injectable()
class UniversalProgressManager
    extends Manager<UniversalProgressState, UniversalProgressEffect> {
  Timer? _timer;
  bool _apiCompleted = false;

  UniversalProgressManager() : super(const UniversalProgressState());

  void startProgressAnimation({
    VoidCallback? onComplete,
    required Future<void> Function() apiCall,
  }) {
    _timer?.cancel();
    _apiCompleted = false;

    const tickDuration = Duration(milliseconds: 100);
    const progressIncrement = 0.01;

    apiCall()
        .then((_) {
          _apiCompleted = true;
          _completeProgress();
        })
        .catchError((error) {
          _apiCompleted = true;
          emit(state.copyWith(hasError: true));
          _completeProgress();
        });

    _timer = Timer.periodic(tickDuration, (timer) {
      final newProgress = (state.progress + progressIncrement).clamp(0.0, 0.90);
      emit(state.copyWith(progress: newProgress));

      if (_apiCompleted && newProgress >= 0.90) {
        timer.cancel();
        _completeProgress();
      }
    });
  }

  void _completeProgress() {
    _timer?.cancel();

    const fastTick = Duration(milliseconds: 30);
    _timer = Timer.periodic(fastTick, (timer) {
      final newProgress = (state.progress + 0.05).clamp(0.0, 1.0);
      emit(state.copyWith(progress: newProgress));

      if (newProgress >= 1.0) {
        timer.cancel();
        emit(state.copyWith(isCompleted: true));
        publish(const UniversalProgressEffect.completed());
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
