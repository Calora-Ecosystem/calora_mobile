import 'dart:async';
import 'dart:io';

import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/common/service/steps/android_step_tracker.dart';
import 'package:calora/common/service/steps/apple_step_tracker.dart';
import 'package:calora/common/service/steps/step_tracker.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:injectable/injectable.dart';

export 'package:calora/common/service/steps/step_tracker.dart'
    show HealthDataNotSyncing, StepCounterEvent, StepSource;

@lazySingleton
class StepCounterService {
  StepCounterService(StepRepo stepRepo, PedometerService pedometer)
    : _tracker = Platform.isAndroid
          ? AndroidStepTracker(stepRepo)
          : AppleStepTracker(stepRepo, pedometer);

  final StepTracker _tracker;

  AndroidStepTracker? get _android =>
      _tracker is AndroidStepTracker ? _tracker : null;

  Stream<int> get stream => _tracker.stream;

  int get currentSteps => _tracker.currentSteps;

  StepSource get source => _tracker.source;

  Stream<StepCounterEvent> get events => _tracker.events;

  Stream<StepSnapshot> get snapshots =>
      _android?.snapshots ?? const Stream.empty();

  StepSnapshot? get lastSnapshot => _android?.lastSnapshot;

  Future<void> start() => _tracker.start();

  Future<void> stop() => _tracker.stop();

  Future<void> refresh() => _tracker.refresh();

  Future<void> retryHealth() => _tracker.retryHealth();

  Future<void> forcePedometer() => _tracker.forcePedometer();

  Future<void> configure({int? goal, double? weightKg, double? kcalPerStep}) =>
      _android?.configure(
        goal: goal,
        weightKg: weightKg,
        kcalPerStep: kcalPerStep,
      ) ??
      Future.value();

  Future<void> syncNotificationLabels() =>
      _android?.syncNotificationLabels() ?? Future.value();

  Future<void> dispose() => _tracker.dispose();
}
