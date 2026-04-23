// lib/common/service/background_steps_worker.dart

import 'dart:developer';
import 'dart:io';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundStepsWorker {
  static const String syncTask = 'steps_sync_periodic';

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      log('Workmanager: initialize()', name: 'BackgroundStepsWorker');

      await Workmanager().initialize(callbackDispatcher);

      await Workmanager().registerPeriodicTask(
        syncTask,
        syncTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 1),
      );
    } catch (e, s) {
      log(
        'Workmanager initialization failed',
        name: 'BackgroundStepsWorker',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  static Future<void> cancel() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelByUniqueName(syncTask);
    log('Workmanager cancelled: $syncTask', name: 'BackgroundStepsWorker');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Hive init
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
      if (!Hive.isBoxOpen(StepLedgerStore.ledgerBoxName)) {
        await Hive.openBox(StepLedgerStore.ledgerBoxName);
      }
      if (!Hive.isBoxOpen(StepLedgerStore.metaBoxName)) {
        await Hive.openBox(StepLedgerStore.metaBoxName);
      }

      if (!GetIt.I.isRegistered<StepRepo>()) {
        await configureDependencies(isBackground: true);
      }

      final stepRepo = GetIt.I<StepRepo>();
      final ledger = StepLedgerStore();

      // Oldingi kunlarning pending sync'ini bajarish (har ikki rejimda ham)
      await _syncPendingDays(stepRepo, ledger);

      // 1. Health rejimini urinib ko'ramiz
      final healthAvailable = await stepRepo.isHealthDataAvailable();
      if (healthAvailable) {
        final authorized = await stepRepo.ensureHealthAuthorized();
        if (authorized) {
          try {
            final steps = await stepRepo.getTodayHealthSteps();
            if (steps > 0) {
              await stepRepo.sendDailyData(metric: 'Step', value: steps);
              final todayKey = ledger.dayKey(DateTime.now());
              await ledger.ensureDayAtLeast(todayKey, steps, minSynced: steps);
              log('BG Health sync: $steps steps', name: 'BackgroundStepsWorker');
            } else {
              log('BG Health: 0 steps today', name: 'BackgroundStepsWorker');
            }
            return true;
          } catch (e) {
            log('BG Health sync failed: $e', name: 'BackgroundStepsWorker');
          }
        }
      }

      // 2. Pedometer fallback (faqat Android)
      await _pedometerBackgroundSync(ledger);
      return true;
    } catch (e, s) {
      log('BG task failed: $e', name: 'BackgroundStepsWorker', error: e, stackTrace: s);
      return false;
    }
  });
}

Future<void> _pedometerBackgroundSync(StepLedgerStore ledger) async {
  try {
    final pedometer = GetIt.I<PedometerService>();
    await pedometer.initialize();
    if (!pedometer.isInitialized) {
      log('BG pedometer not initialized', name: 'BackgroundStepsWorker');
      return;
    }

    final currentSensorTotal = await pedometer.getCurrentSteps();
    final lastSensorTotal = ledger.getLastSensorTotal();
    final todayKey = ledger.dayKey(DateTime.now());

    if (lastSensorTotal >= 0) {
      int delta;
      if (currentSensorTotal < lastSensorTotal) {
        // Reboot
        delta = currentSensorTotal;
        log(
          'BG reboot detected, sensor reset to $currentSensorTotal',
          name: 'BackgroundStepsWorker',
        );
      } else {
        delta = currentSensorTotal - lastSensorTotal;
      }

      if (delta > 0) {
        await ledger.addSteps(todayKey, delta);
        log('BG captured $delta steps', name: 'BackgroundStepsWorker');
      }
    }

    await ledger.setLastSensorTotal(currentSensorTotal);
    await ledger.setLastSensorDate(todayKey);

    // Bugungi umumiy qadamni backend'ga yuborish
    final total = ledger.totalFor(todayKey);
    final synced = ledger.syncedFor(todayKey);
    if (total > synced) {
      final stepRepo = GetIt.I<StepRepo>();
      await stepRepo.sendDailyData(metric: 'Step', value: total);
      await ledger.setSynced(todayKey, total);
      log('BG pedometer sync: $total steps', name: 'BackgroundStepsWorker');
    }
  } catch (e, s) {
    log('BG pedometer sync error: $e', name: 'BackgroundStepsWorker', error: e, stackTrace: s);
  }
}

Future<void> _syncPendingDays(StepRepo stepRepo, StepLedgerStore ledger) async {
  try {
    final pendingDays = ledger.getAllPendingDays();
    final todayKey = ledger.dayKey(DateTime.now());
    final pastDays = pendingDays.where((k) => k != todayKey).toList();

    if (pastDays.isEmpty) return;

    final payload = pastDays.map((key) {
      return StepsWithMetricsRequest(
        date: DateTime.parse(key),
        value: ledger.totalFor(key).toDouble(),
      );
    }).toList();

    await stepRepo.sendStepDataDateRange(steps: payload);

    for (final key in pastDays) {
      await ledger.deleteDay(key);
    }
    log('BG synced ${pastDays.length} past days', name: 'BackgroundStepsWorker');
  } catch (e) {
    log('BG pending days sync error: $e', name: 'BackgroundStepsWorker');
  }
}
