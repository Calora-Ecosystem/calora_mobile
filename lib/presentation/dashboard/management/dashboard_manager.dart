// lib/presentation/dashboard/management/dashboard_manager.dart

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/service/device_care_service.dart';
import 'package:calora/common/service/foreground_service.dart';
import 'package:calora/common/service/installed_health_apps_service.dart';
import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/data/store/auth/auth_store.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora/presentation/dashboard/management/dashboard_management.dart';
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
  StreamSubscription<StepCounterEvent>? _stepEventsSub;
  StreamSubscription<void>? _forceLogoutSub;

  bool _initialized = false;
  Future<void>? _initFuture;

  DashboardManager(this._stepRepo, this._stepCounter, this._authStore)
      : super(const DashboardState());

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
        await StepsForegroundService.instance.stop();
        publish(const DashboardEffect.forceLogout());
      });

      _listenToStepCounter();
      _listenToStepEvents();
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

  void _listenToStepEvents() {
    _stepEventsSub?.cancel();
    _stepEventsSub = _stepCounter.events.listen((event) {
      switch (event) {
        case HealthDataNotSyncing():
          publish(DashboardEffect.requestHealthSyncFix(
            detectedApp: event.detectedApp,
          ));
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // Stuck-Health dialog actions (called from the UI)
  // ─────────────────────────────────────────────────────────────────────

  Future<void> onOpenHealthApp(String detectedApp) async {
    // Deep-link straight to the Health Connect screen where the user
    // manages this tracker's data sharing, so they can flip "Allow all"
    // for Samsung Health / Google Fit and start writing Steps into
    // Health Connect. Falls back to Health Connect's main settings
    // natively when the tracker is unknown.
    await DeviceCareService.openHealthConnectAppPermissions(detectedApp: detectedApp);
    await _ledger.setUserOpenedHealthApp(true);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Battery-optimization whitelist prompt (background reliability)
  // ─────────────────────────────────────────────────────────────────────

  /// True when we should show the battery-whitelist dialog: Android, the
  /// app isn't already exempt, and we haven't shown it before.
  Future<bool> shouldPromptBatteryWhitelist() async {
    if (!Platform.isAndroid) return false;
    if (_ledger.isBatteryHintShown()) return false;
    return !await DeviceCareService.isIgnoringBatteryOptimizations();
  }

  Future<void> markBatteryHintShown() => _ledger.setBatteryHintShown();

  Future<void> onUseSensorInstead() async {
    await _stepCounter.forcePedometer();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Permission rationale flow (UI concern — kept here)
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _decideStepCounterStart() async {
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
      // Previously accepted — re-request silently in case it was revoked.
      unawaited(_stepRepo.requestHealthPermission());
      await _stepCounter.start();
      return;
    }

    final detectedApp = Platform.isAndroid
        ? (await InstalledHealthAppsService.detectPrimaryHealthApp() ?? 'unknown')
        : 'ios';
    publish(DashboardEffect.requestHealthPermission(detectedApp: detectedApp));
  }

  /// User tapped "Yes" on the rationale dialog.
  Future<void> onUserAcceptedHealthPermission() async {
    await _ledger.setHealthHintShown();

    final granted = await _stepRepo.requestHealthPermission();
    if (granted || Platform.isIOS) {
      await _stepCounter.start();
      await _stepCounter.retryHealth();
      return;
    }

    // Android denial — send user to device settings.
    await _ledger.setUserOpenedHealthApp(true);
    await _stepRepo.openHealthSettings();
    await _stepCounter.start();
  }

  /// User tapped "No" on the rationale dialog.
  Future<void> onUserDeclinedHealthPermission() async {
    await _ledger.setHealthHintDismissed();
    await _stepCounter.start();
  }

  // ─────────────────────────────────────────────────────────────────────
  // App lifecycle — re-check permission after user returns from settings
  // ─────────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState != AppLifecycleState.resumed) return;

    if (_ledger.didUserOpenHealthApp()) {
      unawaited(_recheckAfterUserReturn());
      return;
    }

    // iOS-specific: HealthKit doesn't expose read-permission status,
    // so we can't tell when the user fixes it in Settings on their
    // own. Cheap workaround — every time the app comes to the
    // foreground and we're not already on Health, ask the service to
    // try again. `retryHealth` is a no-op if Health is already
    // active, and silently bails if the probe still returns 0, so
    // this is safe to fire on every resume.
    if (Platform.isIOS && _stepCounter.source != StepSource.health) {
      unawaited(_stepCounter.retryHealth());
    }
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
    _stepEventsSub?.cancel();
    _forceLogoutSub?.cancel();
    return super.close();
  }
}
