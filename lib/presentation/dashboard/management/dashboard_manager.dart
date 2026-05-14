// lib/presentation/dashboard/management/dashboard_manager.dart

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:calora/common/base/step_ledger_store.dart';
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
      _maybeStartForegroundService(total);
    });
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
    if (lifecycleState == AppLifecycleState.resumed &&
        _ledger.didUserOpenHealthApp()) {
      unawaited(_recheckAfterUserReturn());
    }
  }

  Future<void> _recheckAfterUserReturn() async {
    await _ledger.setUserOpenedHealthApp(false);
    await Future.delayed(const Duration(seconds: 2));
    await _stepCounter.retryHealth();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Android foreground notification — start lazily on first non-zero count
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _maybeStartForegroundService(int currentSteps) async {
    if (!Platform.isAndroid) return;
    if (StepsForegroundService.instance.isRunning) return;

    final started = await StepsForegroundService.instance.start();
    if (started) {
      unawaited(StepsForegroundService.instance.syncSteps(currentSteps));
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _stepsSub?.cancel();
    _forceLogoutSub?.cancel();
    return super.close();
  }
}
