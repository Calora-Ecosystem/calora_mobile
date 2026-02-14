import 'dart:developer';
import 'dart:io';

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
        isInDebugMode: false, // Set to true for debugging work manager calls
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
      // Initialize dependencies for the background isolate
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
      if (!Hive.isBoxOpen(StepLedgerStore.ledgerBoxName)) {
        await Hive.openBox(StepLedgerStore.ledgerBoxName);
      }
      if (!Hive.isBoxOpen(StepLedgerStore.metaBoxName)) {
        await Hive.openBox(StepLedgerStore.metaBoxName);
      }

      // Using a flag to ensure DI is configured only once.
      if (!GetIt.I.isRegistered<StepRepo>()) {
        configureDependencies();
      }
      
      final ledger = StepLedgerStore();
      final pendingDays = ledger.getAllPendingDays();

      log('BG task=$task running. Found ${pendingDays.length} pending days.', name: 'BackgroundStepsWorker');

      if (pendingDays.isNotEmpty) {
        final ok = await _syncPendingSteps(pendingDays);
        return ok;
      }

      return true; // Nothing to do
    } catch (e, s) {
      log('BG task failed: $e', name: 'BackgroundStepsWorker', error: e, stackTrace: s);
      return false; // Reschedule task
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

    // Sync and then DELETE past days in a batch
    if (pastDaysToSync.isNotEmpty) {
      final payload = pastDaysToSync.map((key) {
        return StepsWithMetricsRequest(
          date: DateTime.parse(key),
          value: ledger.totalFor(key).toDouble(),
        );
      }).toList();
      
      await stepRepo.sendStepDataDateRange(steps: payload);
      
      // On success, delete the days from Hive
      for (final dayKey in pastDaysToSync) {
        await ledger.deleteDay(dayKey);
      }
      log('Synced and cleared ${pastDaysToSync.length} past days in background.', name: 'BackgroundStepsWorker');
    }

    // Sync today but DO NOT delete
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
