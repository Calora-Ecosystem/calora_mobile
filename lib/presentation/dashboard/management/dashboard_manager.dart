import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
import 'package:calora/presentation/step_sources/step_connect.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:management/management.dart';

@injectable
class DashboardManager extends Manager<DashboardState, DashboardEffect>
    with WidgetsBindingObserver {
  final StepRepo _stepRepo;
  final StepCounterService _stepCounter;
  final AuthStore _authStore;

  final StepLedgerStore _ledger = StepLedgerStore();

  StreamSubscription<int>? _stepsSub;
  StreamSubscription<void>? _forceLogoutSub;

  bool _initialized = false;
  Future<void>? _initFuture;
  StepTrackingStatus _stepStatus = StepTrackingStatus.unknown;
  bool _awaitingHealthConnectInstall = false;
  String? _offeredTrackerId;
  String? _pendingTrackerOffer;

  DashboardManager(this._stepRepo, this._stepCounter, this._authStore)
    : super(const DashboardState());

  StepTrackingStatus get stepStatus => _stepStatus;

  Future<void> get ready => _initFuture ?? Future.value();

  String? takeTrackerOffer() {
    final offer = _pendingTrackerOffer;
    _pendingTrackerOffer = null;
    return offer;
  }

  TrackerAppStatus? trackerById(String id) =>
      _stepStatus.trackers.firstWhereOrNull((t) => t.id == id);

  @override
  void initialize() {
    super.initialize();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _initFuture ??= _initializeInternal();
  }

  Future<void> _initializeInternal() async {
    try {
      _forceLogoutSub?.cancel();
      _forceLogoutSub = _authStore.onForceLogout.listen((_) async {
        await _stepCounter.stop();
        publish(const DashboardEffect.forceLogout());
      });

      _listenToStepCounter();
      await _decideStepCounterStart();
    } catch (e, s) {
      log('DashboardManager init error: $e', stackTrace: s);
    }
  }

  void _listenToStepCounter() {
    _stepsSub?.cancel();
    _stepsSub = _stepCounter.stream.listen((total) {
      if (state.todaySteps != total) {
        emit(state.copyWith(todaySteps: total));
      }
    });
  }

  Future<void> _decideStepCounterStart() async {
    if (Platform.isAndroid) {
      await _stepCounter.start();
      await _maybeOfferTrackerConnect();
      return;
    }

    final healthAvailable = await _stepRepo.isHealthDataAvailable();
    if (!healthAvailable) {
      await _stepCounter.start();
      return;
    }

    if (await _stepRepo.hasHealthPermission()) {
      await _stepCounter.start();
      return;
    }

    if (_ledger.isHealthHintDismissed()) {
      await _stepCounter.start();
      return;
    }

    if (_ledger.isHealthHintShown()) {
      unawaited(_stepRepo.requestHealthPermission());
      await _stepCounter.start();
      return;
    }

    publish(const DashboardEffect.requestHealthPermission(detectedApp: 'ios'));
  }

  Future<void> _maybeOfferTrackerConnect() async {
    if (_ledger.isHealthHintShown() || _ledger.isHealthHintDismissed()) return;
    _stepStatus = await CaloraSteps.status();
    if (_stepStatus.healthConnectConnected) return;
    if (_stepStatus.healthConnect == HealthConnectAvailability.unsupported) {
      return;
    }
    final tracker = _stepStatus.trackers.firstOrNull;
    if (tracker == null) return;
    _offeredTrackerId = tracker.id;
    _pendingTrackerOffer = tracker.id;
  }

  Future<StepConnectOutcome?> onUserAcceptedHealthPermission() async {
    await _ledger.setHealthHintShown();

    if (Platform.isAndroid) return _connectHealthConnect(publishFix: false);

    final granted = await _stepRepo.requestHealthPermission();
    if (granted || Platform.isIOS) {
      await _stepCounter.start();
      await _stepCounter.retryHealth();
      return null;
    }

    await _ledger.setUserOpenedHealthApp(true);
    await _stepRepo.openHealthSettings();
    await _stepCounter.start();
    return null;
  }

  Future<void> onUserDeclinedHealthPermission() async {
    await _ledger.setHealthHintDismissed();
    await _stepCounter.start();
  }

  Future<StepConnectOutcome> _connectHealthConnect({
    required bool publishFix,
  }) async {
    final outcome = await linkHealthConnect(
      _stepCounter,
      trackerId: _offeredTrackerId,
    );
    _awaitingHealthConnectInstall =
        outcome.result == HealthConnectConnectResult.storeOpened;
    _stepStatus = await CaloraSteps.status();
    final tracker = outcome.trackerNeedsSetup;
    if (publishFix && tracker != null) {
      publish(DashboardEffect.requestHealthSyncFix(detectedApp: tracker.id));
    }
    return outcome;
  }

  Future<void> onOpenHealthApp(String detectedApp) async {
    final tracker = trackerById(detectedApp);
    if (tracker == null) {
      await CaloraSteps.openHealthConnect();
    } else {
      await CaloraSteps.openTracker(tracker.packageName);
    }
    await _ledger.setUserOpenedHealthApp(true);
  }

  Future<bool> shouldPromptBatteryWhitelist() async {
    if (!Platform.isAndroid) return false;
    if (_ledger.isBatteryHintShown()) return false;
    final status = await CaloraSteps.status();
    return !status.batteryUnrestricted;
  }

  Future<void> markBatteryHintShown() => _ledger.setBatteryHintShown();

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState != AppLifecycleState.resumed) return;

    if (Platform.isAndroid) {
      unawaited(_onAndroidResumed());
      return;
    }

    if (_ledger.didUserOpenHealthApp()) {
      unawaited(_recheckAfterUserReturn());
      return;
    }

    if (_stepCounter.source != StepSource.health) {
      unawaited(_stepCounter.retryHealth());
    }
  }

  Future<void> _onAndroidResumed() async {
    await _stepCounter.refresh();
    if (_ledger.didUserOpenHealthApp()) {
      await _ledger.setUserOpenedHealthApp(false);
    }
    if (!_awaitingHealthConnectInstall) return;
    final status = await CaloraSteps.status();
    if (status.healthConnect != HealthConnectAvailability.available) return;
    _awaitingHealthConnectInstall = false;
    await _connectHealthConnect(publishFix: true);
  }

  Future<void> _recheckAfterUserReturn() async {
    await _ledger.setUserOpenedHealthApp(false);
    await Future.delayed(const Duration(seconds: 2));
    await _stepCounter.retryHealth();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _stepsSub?.cancel();
    _forceLogoutSub?.cancel();
    return super.close();
  }
}
