import 'dart:developer';
import 'dart:io';

import 'package:calora/common/base/step_ledger_db.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/service/step_sync_service.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:calora_steps/calora_steps.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundStepsWorker {
  static const String syncTask = 'steps_sync_periodic';
  static const String chainSyncTask = 'steps_sync_chain';
  static const String iosRefreshTask = 'com.calora.stepsync';
  static const Duration chainInterval = Duration(minutes: 4);

  static Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await Workmanager().initialize(callbackDispatcher);

      if (Platform.isAndroid) {
        await Workmanager().registerPeriodicTask(
          syncTask,
          syncTask,
          frequency: const Duration(minutes: 15),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          backoffPolicy: BackoffPolicy.linear,
          backoffPolicyDelay: const Duration(minutes: 1),
        );
        await scheduleNextChainSync(ExistingWorkPolicy.replace);
      } else {
        await Workmanager().registerPeriodicTask(
          iosRefreshTask,
          iosRefreshTask,
        );
      }
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

  static Future<void> scheduleNextChainSync(ExistingWorkPolicy policy) async {
    if (!Platform.isAndroid) return;
    await Workmanager().registerOneOffTask(
      chainSyncTask,
      chainSyncTask,
      initialDelay: chainInterval,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: policy,
    );
  }

  static Future<void> cancel() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await Workmanager().cancelByUniqueName(syncTask);
    if (Platform.isAndroid) {
      await Workmanager().cancelByUniqueName(chainSyncTask);
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (Platform.isAndroid && task == BackgroundStepsWorker.syncTask) {
        await _refreshNativeEngine(history: false);
        await BackgroundStepsWorker.scheduleNextChainSync(
          ExistingWorkPolicy.keep,
        );
        return true;
      }

      await _runFullSync();
      return true;
    } catch (e, s) {
      log(
        'BG task failed: $e',
        name: 'BackgroundStepsWorker',
        error: e,
        stackTrace: s,
      );
      return true;
    } finally {
      if (Platform.isAndroid && task == BackgroundStepsWorker.chainSyncTask) {
        try {
          await BackgroundStepsWorker.scheduleNextChainSync(
            ExistingWorkPolicy.replace,
          );
        } catch (e) {
          log('Chain re-schedule failed: $e', name: 'BackgroundStepsWorker');
        }
      }
    }
  });
}

Future<void> _runFullSync() async {
  if (!dotenv.isInitialized) await dotenv.load();
  if (!GetIt.I.isRegistered<StepRepo>()) {
    await configureDependencies(isBackground: true);
  }

  final stepRepo = GetIt.I<StepRepo>();
  final db = StepLedgerDb.instance;
  final sync = StepSyncService(stepRepo);

  if (Platform.isAndroid) {
    final history = await _refreshNativeEngine(history: true);
    if (history.isNotEmpty) await db.hydrateFromNativeHistory(history);
  } else {
    await sync.hydrateHealthHistory(days: 7, oncePerDay: true);
    final healthSteps = await _readTodayAppleHealthSteps(stepRepo);
    if (healthSteps > 0) {
      await db.ensureDayAtLeast(
        StepLedgerDb.dayKey(DateTime.now()),
        healthSteps,
      );
    }
  }

  await db.pruneOldLedgerDays();
  await db.pruneOldBackendSyncKeys();
  await sync.syncPendingToBackend();
}

Future<Map<String, int>> _refreshNativeEngine({required bool history}) async {
  try {
    await CaloraSteps.ensureRunning();
    await CaloraSteps.refresh();
    if (!history) return const {};
    return await CaloraSteps.history(refresh: true);
  } catch (e) {
    log('Native step refresh failed: $e', name: 'BackgroundStepsWorker');
    return const {};
  }
}

Future<int> _readTodayAppleHealthSteps(StepRepo stepRepo) async {
  try {
    if (!await stepRepo.isHealthDataAvailable()) return 0;
    return await stepRepo.getHealthStepsForDay(DateTime.now());
  } catch (e) {
    log('BG health read failed: $e', name: 'BackgroundStepsWorker');
    return 0;
  }
}
