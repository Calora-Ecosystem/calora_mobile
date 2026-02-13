import 'dart:developer';
import 'dart:io';

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
      // Hive init (BG isolate)
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
      if (!Hive.isBoxOpen('steps_ledger')) await Hive.openBox('steps_ledger');
      if (!Hive.isBoxOpen('steps_meta')) await Hive.openBox('steps_meta');

      // DI init (GetIt)
      configureDependencies();

      final ledger = StepLedgerStore();
      final todayKey = ledger.dayKey(DateTime.now());
      final total = ledger.totalFor(todayKey);
      final synced = ledger.syncedFor(todayKey);

      log('BG task=$task total=$total synced=$synced', name: 'BackgroundStepsWorker');

      if (total > synced && total > 0) {
        final ok = await _sendSteps(total);
        return ok;
      }

      return true;
    } catch (e, s) {
      log('BG task failed: $e', name: 'BackgroundStepsWorker', error: e, stackTrace: s);
      return false;
    }
  });
}

Future<bool> _sendSteps(int total) async {
  try {
    final stepRepo = GetIt.instance<StepRepo>();
    final ledger = StepLedgerStore();
    final todayKey = ledger.dayKey(DateTime.now());

    await stepRepo.sendDailyData(metric: 'Step', value: total);
    await ledger.setSynced(todayKey, total);

    log('Sent $total steps', name: 'BackgroundStepsWorker');
    return true;
  } catch (e, s) {
    log('Send steps failed: $e', name: 'BackgroundStepsWorker', error: e, stackTrace: s);
    return false;
  }
}
