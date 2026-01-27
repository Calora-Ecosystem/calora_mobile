import 'dart:async';
import 'dart:developer';

import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/language/language.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/app/app/management/app_management.dart';
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
      log('⏰ Periodic sync timer triggered');
    });
  }

  void stopPeriodicDataSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    log('Stopped periodic data sync from AppManager.');
  }

  void select(Language language) => emit(state.copyWith(language: language));

  @override
  Future<void> close() {
    _premiumSub?.cancel();
    stopPeriodicDataSync();
    return super.close();
  }
}
