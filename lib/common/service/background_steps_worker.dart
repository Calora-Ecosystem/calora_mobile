import 'dart:developer';
import 'dart:io';

import 'package:calora/common/service/pedometer_service.dart';
import 'package:calora/domain/model/dailies/steps_stat.dart';
import 'package:workmanager/workmanager.dart';

import 'package:calora/common/di/injection.dart';
import 'package:get_it/get_it.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:calora/common/base/step_ledger_store.dart';

class BackgroundStepsWorker {
  static const String syncTask = 'steps_sync_periodic';

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      log('Workmanager: initialize()', name: 'BackgroundStepsWorker');

      await Workmanager().initialize(
        callbackDispatcher,
      );

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
      log('Workmanager initialization failed', name: 'BackgroundStepsWorker', error: e, stackTrace: s);
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
      
      final ledger = StepLedgerStore();
      final pedometer = GetIt.I<PedometerService>();

      await pedometer.initialize();

      try {
        final currentSensorTotal = await pedometer.getCurrentSteps();
        final lastSensorTotal = ledger.getLastSensorTotal();
        
        if (lastSensorTotal >= 0) {
          int delta;
          if (currentSensorTotal < lastSensorTotal) {
            delta = currentSensorTotal;
            log('BG Reboot detected. Sensor reset to $currentSensorTotal', name: 'BackgroundStepsWorker');
          } else {
            delta = currentSensorTotal - lastSensorTotal;
          }

          if (delta > 0) {
            final todayKey = ledger.dayKey(DateTime.now());
            await ledger.addSteps(todayKey, delta);
            await ledger.setLastSensorTotal(currentSensorTotal);
            await ledger.setLastSensorDate(todayKey);
            log('BG captured $delta steps. New sensor total: $currentSensorTotal', name: 'BackgroundStepsWorker');
          } else {
             log('BG no new steps (delta: $delta)', name: 'BackgroundStepsWorker');
          }
        } else {
          await ledger.setLastSensorTotal(currentSensorTotal);
          await ledger.setLastSensorDate(ledger.dayKey(DateTime.now()));
          log('BG initialized sensor total to $currentSensorTotal', name: 'BackgroundStepsWorker');
        }
      } catch (e) {
        log('BG sensor read failed: $e', name: 'BackgroundStepsWorker');
      }

      final pendingDays = ledger.getAllPendingDays();

      log('BG task=$task running. Found ${pendingDays.length} pending days.', name: 'BackgroundStepsWorker');

      if (pendingDays.isNotEmpty) {
        final ok = await _syncPendingSteps(pendingDays);
        await Future.delayed(const Duration(milliseconds: 500));
        return ok;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e, s) {
      log('BG task failed: $e', name: 'BackgroundStepsWorker', error: e, stackTrace: s);
      return false;
    }
  });
}

Future<bool> _syncPendingSteps(List<String> pendingDays) async {
  try {
    final stepRepo = GetIt.instance<StepRepo>();
    final ledger = StepLedgerStore();
    final todayKey = ledger.dayKey(DateTime.now());

    final pastDaysToSync = pendingDays.where((key) => key != todayKey).toList();
    final todayToSync = pendingDays.firstWhere((key) => key == todayKey, orElse: () => '');

    if (pastDaysToSync.isNotEmpty) {
      final payload = pastDaysToSync.map((key) {
        return StepsWithMetricsRequest(
          date: DateTime.parse(key),
          value: ledger.totalFor(key).toDouble(),
        );
      }).toList();
      
      await stepRepo.sendStepDataDateRange(steps: payload);
      
      for (final dayKey in pastDaysToSync) {
        await ledger.deleteDay(dayKey);
      }
      log('Synced and cleared ${pastDaysToSync.length} past days in background.', name: 'BackgroundStepsWorker');
    }

    if (todayToSync.isNotEmpty) {
      final total = ledger.totalFor(todayToSync);
      if (total > 0) {
        await stepRepo.sendDailyData(metric: 'Step', value: total);
        await ledger.setSynced(todayToSync, total);
        log('Synced $total steps for today in background.', name: 'BackgroundStepsWorker');
      }
    }
    
    return true;
  } catch (e, s) {
    log('Syncing pending steps failed: $e', name: 'BackgroundStepsWorker', error: e, stackTrace: s);
    return false;
  }
}
