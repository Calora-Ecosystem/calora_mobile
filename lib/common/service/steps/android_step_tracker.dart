import 'dart:async';
import 'dart:developer';

import 'package:calora/common/base/step_ledger_db.dart';
import 'package:calora/common/service/step_sync_service.dart';
import 'package:calora/common/service/steps/step_tracker.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rxdart/rxdart.dart';

class AndroidStepTracker implements StepTracker {
  AndroidStepTracker(StepRepo stepRepo) : _sync = StepSyncService(stepRepo);

  final StepSyncService _sync;
  final StepLedgerDb _db = StepLedgerDb.instance;

  static const _backendSyncInterval = Duration(minutes: 1);
  static const _ledgerWriteGap = Duration(seconds: 5);
  static const _historyGap = Duration(minutes: 5);

  final _subject = BehaviorSubject<int>.seeded(0);
  final _snapshots = BehaviorSubject<StepSnapshot>();
  final _events = StreamController<StepCounterEvent>.broadcast();

  StreamSubscription<StepSnapshot>? _updates;
  Timer? _backendTimer;
  Future<void>? _starting;
  String? _ledgerDay;
  int _ledgerSteps = 0;
  DateTime _ledgerWrittenAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _historyAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Stream<int> get stream => _subject.stream;

  @override
  int get currentSteps => _subject.valueOrNull ?? 0;

  @override
  StepSource get source => switch (_snapshots.valueOrNull?.source) {
    StepSourceKind.healthConnect => StepSource.health,
    null => StepSource.none,
    _ => StepSource.pedometer,
  };

  @override
  Stream<StepCounterEvent> get events => _events.stream;

  Stream<StepSnapshot> get snapshots => _snapshots.stream;

  StepSnapshot? get lastSnapshot => _snapshots.valueOrNull;

  @override
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    _updates ??= CaloraSteps.updates.listen(
      _onSnapshot,
      onError: (Object e) =>
          log('Step updates failed: $e', name: 'AndroidStepTracker'),
    );
    final cached = await _guardValue(
      () => _db.totalFor(StepLedgerDb.dayKey(DateTime.now())),
      0,
    );
    if (cached > currentSteps && lastSnapshot == null) _subject.add(cached);

    await syncNotificationLabels();
    _onSnapshot(await CaloraSteps.start());
    _onSnapshot(await CaloraSteps.refresh());
    unawaited(_hydrateHistory(force: true));
    _startBackendSync();
  }

  @override
  Future<void> stop() async {
    _backendTimer?.cancel();
    _backendTimer = null;
    await _updates?.cancel();
    _updates = null;
    _starting = null;
    await CaloraSteps.stop();
  }

  @override
  Future<void> refresh() async {
    if (_starting == null) return;
    await _starting;
    _onSnapshot(await CaloraSteps.start());
    _onSnapshot(await CaloraSteps.refresh(force: true));
    unawaited(_hydrateHistory());
  }

  @override
  Future<void> retryHealth() => refresh();

  @override
  Future<void> forcePedometer() async {}

  @override
  Future<void> dispose() async {
    await stop();
    await _subject.close();
    await _snapshots.close();
    await _events.close();
  }

  Future<void> configure({int? goal, double? weightKg, double? kcalPerStep}) =>
      CaloraSteps.configure(
        goal: goal,
        weightKg: weightKg,
        kcalPerStep: kcalPerStep,
      );

  Future<void> syncNotificationLabels() => CaloraSteps.configure(
    labels: StepNotificationLabels(
      channel: 'steps_notif_channel'.tr(),
      title: 'steps_notif_title'.tr(),
      goal: 'steps_notif_goal'.tr(),
      kcal: 'steps_notif_kcal'.tr(),
      goalReached: 'steps_notif_goal_reached'.tr(),
      locale: 'steps_locale_code'.tr(),
    ),
  );

  void _onSnapshot(StepSnapshot snapshot) {
    if (_snapshots.isClosed) return;
    if (snapshot.day == null) return;
    _snapshots.add(snapshot);
    final today = StepLedgerDb.dayKey(DateTime.now());
    if (snapshot.day != today) return;
    if (_subject.valueOrNull != snapshot.steps) _subject.add(snapshot.steps);
    unawaited(_writeLedger(today, snapshot.steps));
  }

  Future<void> _writeLedger(String day, int steps, {bool force = false}) async {
    if (steps <= 0) return;
    final now = DateTime.now();
    final sameDay = _ledgerDay == day;
    if (sameDay && steps <= _ledgerSteps) return;
    if (!force && sameDay && now.difference(_ledgerWrittenAt) < _ledgerWriteGap)
      return;
    _ledgerDay = day;
    _ledgerSteps = steps;
    _ledgerWrittenAt = now;
    await _guard('Ledger write', () => _db.ensureDayAtLeast(day, steps));
  }

  Future<void> _hydrateHistory({bool force = false}) async {
    final now = DateTime.now();
    if (!force && now.difference(_historyAt) < _historyGap) return;
    _historyAt = now;
    await _guard('History hydration', () async {
      final history = await CaloraSteps.history(refresh: true, force: force);
      if (history.isNotEmpty) await _db.hydrateFromNativeHistory(history);
      await _sync.syncPendingToBackend();
    });
  }

  void _startBackendSync() {
    _backendTimer?.cancel();
    _backendTimer = Timer.periodic(
      _backendSyncInterval,
      (_) => unawaited(_guard('Backend sync', _pushToBackend)),
    );
  }

  Future<void> _pushToBackend() async {
    final day = StepLedgerDb.dayKey(DateTime.now());
    if (lastSnapshot?.day == day)
      await _writeLedger(day, currentSteps, force: true);
    await _sync.syncPendingToBackend();
  }

  Future<void> _guard(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (e, s) {
      log('$label failed: $e', name: 'AndroidStepTracker', stackTrace: s);
    }
  }

  Future<T> _guardValue<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } catch (_) {
      return fallback;
    }
  }
}
