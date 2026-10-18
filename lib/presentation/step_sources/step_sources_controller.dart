import 'dart:async';

import 'package:calora/common/service/step_counter_service.dart';
import 'package:calora/presentation/step_sources/step_connect.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class StepSourcesController extends ChangeNotifier with WidgetsBindingObserver {
  StepSourcesController(this._stepCounter);

  final StepCounterService _stepCounter;

  StepTrackingStatus status = StepTrackingStatus.unknown;
  StepSnapshot snapshot = StepSnapshot.empty;
  bool loading = true;
  bool busy = false;

  StreamSubscription<StepSnapshot>? _snapshots;
  bool _awaitingInstall = false;
  bool _disposed = false;

  bool get counting =>
      status.hasAnySource &&
      (snapshot.issue == null || snapshot.issue == StepIssue.serviceStopped);

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    snapshot = _stepCounter.lastSnapshot ?? snapshot;
    _snapshots = _stepCounter.snapshots.listen((value) {
      snapshot = value;
      _notify();
    });
    await reload();
    unawaited(refreshAll());
  }

  Future<void> reload() async {
    status = await CaloraSteps.status();
    loading = false;
    _notify();
  }

  Future<void> refreshAll() async {
    await _stepCounter.refresh();
    snapshot = _stepCounter.lastSnapshot ?? snapshot;
    await reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_onResumed());
  }

  Future<void> _onResumed() async {
    await refreshAll();
    if (_awaitingInstall &&
        status.healthConnect == HealthConnectAvailability.available) {
      _awaitingInstall = false;
      await connectHealthConnect();
    }
  }

  Future<void> requestActivity() => _run(() async {
    final result = await Permission.activityRecognition.request();
    if (result.isPermanentlyDenied || result.isRestricted) {
      await CaloraSteps.openAppSettings();
      return;
    }
    if (result.isGranted) await _stepCounter.refresh();
  });

  Future<void> requestNotifications() => _run(() async {
    final result = await Permission.notification.request();
    if (!result.isGranted) await CaloraSteps.openNotificationSettings();
  });

  Future<void> requestBattery() =>
      _run(CaloraSteps.requestIgnoreBatteryOptimizations);

  Future<void> openAutoStart() => _run(CaloraSteps.openAutoStart);

  Future<void> openHealthConnect() => _run(CaloraSteps.openHealthConnect);

  Future<void> openTracker(TrackerAppStatus tracker) =>
      _run(() => CaloraSteps.openTracker(tracker.packageName));

  Future<StepConnectOutcome?> connectHealthConnect() async {
    if (busy) return null;
    busy = true;
    _notify();
    try {
      final outcome = await linkHealthConnect(_stepCounter);
      if (outcome.result == HealthConnectConnectResult.storeOpened)
        _awaitingInstall = true;
      await reload();
      return outcome;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    _notify();
    try {
      await action();
    } finally {
      busy = false;
      await reload();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _snapshots?.cancel();
    super.dispose();
  }
}
