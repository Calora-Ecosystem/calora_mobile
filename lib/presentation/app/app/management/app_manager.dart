import 'dart:async';
import 'dart:developer';

import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';
import 'package:calora/presentation/dashboard/features/steps/management/steps_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class AppManager extends Manager<AppState, AppEffect> {
  final CommonStore _commonStore;
  final StepRepo _stepRepo;
  StreamSubscription<bool>? _premiumSub;
  Timer? _periodicTimer;

  AppManager(this._commonStore, this._stepRepo) : super(const AppState()) {
    _init();
  }

  Future<void> _init() async {
    final isPremium = await _commonStore.isUserPremium();
    emit(state.copyWith(isUserPremium: isPremium));
    _premiumSub = _commonStore.isUserPremium.watch().listen((value) {
      emit(state.copyWith(isUserPremium: value));
    });
  }

  void startPeriodicDataSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      log('Sending daily data from AppManager...');
      sendDailyData();
    });
    log('Sending initial daily data from AppManager...');
    sendDailyData();
  }

  void stopPeriodicDataSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    log('Stopped periodic data sync from AppManager.');
  }

  Future<void> sendDailyData() async {
    try {
      final currentStepCount = state.stepCount;
      await _stepRepo.sendDailyData(metric: 'Step', value: currentStepCount);
      log('Daily data sent: $currentStepCount steps.');
    } catch (e, s) {
      log('Error sending daily data from AppManager: $e \n $s');
    }
  }

  void updateSteps(int steps) => emit(state.copyWith(stepCount: steps));
  void select(Language language) => emit(state.copyWith(language: language));

  @override
  Future<void> close() {
    _premiumSub?.cancel();
    stopPeriodicDataSync();
    return super.close();
  }
}
