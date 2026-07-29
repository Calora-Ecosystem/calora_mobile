// lib/common/service/background_steps_worker.dart

import 'dart:developer';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:calora/common/base/step_ledger_db.dart';
import 'package:calora/common/di/injection.dart';
import 'package:calora/common/service/step_sync_service.dart';
import 'package:calora/domain/repo/step/step_repo.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

/// Background step sync scheduling.
///
/// Android:
///  • [chainSyncTask] — self-rechaining one-off WorkManager task. Runs
///    the full sync and re-enqueues itself with a [chainInterval] delay,
///    which is how the backend gets its 2–5-min cadence (periodic
///    WorkManager is hard-floored at 15 min, one-off tasks are not).
///    Doze can defer a run to the next maintenance window; the
///    battery-optimization exemption the app already prompts for lifts
///    that on most devices.
///  • [syncTask] — 15-min periodic task acting as a watchdog only: kicks
///    the native FG service back up and re-enqueues the chain if an OEM
///    kill, crash, or force-stop broke it. It does no syncing and opens
///    no storage itself, so it can never collide with a running chain
///    task.
/// iOS:
///  • [iosRefreshTask] — BGAppRefreshTask (identifier registered in
///    Info.plist + AppDelegate). iOS decides the real cadence; the
///    on-open HealthKit backfill is what guarantees no data loss.
///
/// Counting model (the permanent overcount fix): this worker NEVER
/// touches raw sensor streams (`pedometer_2` is not even imported). The
/// native StepsFgService is the only step counter on Android; the worker
/// reads its persisted ABSOLUTE totals straight from
/// `calora_steps_native.xml` (plus the Health Connect aggregate, which
/// de-duplicates across source apps) and merges both into the SQLite
/// ledger with max-semantics via `StepLedgerDb.ensureDayAtLeast`. With
/// no delta-accumulation anywhere in the background path, the same
/// physical step can never be counted twice, no matter how the tasks
/// interleave.
///
/// Battery: each chain run is a few prefs/DB reads and at most one small
/// POST, completing in well under a second of CPU — far below the
/// thresholds Android vitals flags. The task requires network, so
/// offline periods produce no spinning retries: WorkManager simply holds
/// the task until connectivity returns.
class BackgroundStepsWorker {
  static const String syncTask = 'steps_sync_periodic';
  static const String chainSyncTask = 'steps_sync_chain';

  /// iOS BGAppRefreshTask identifier — keep in sync with Info.plist and
  /// AppDelegate.swift.
  static const String iosRefreshTask = 'com.calora.stepsync';

  /// Cadence of the Android one-off chain (QA requirement: 2–5 min).
  static const Duration chainInterval = Duration(minutes: 4);

  static Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      log('Workmanager: initialize()', name: 'BackgroundStepsWorker');

      await Workmanager().initialize(callbackDispatcher);

      if (Platform.isAndroid) {
        await Workmanager().registerPeriodicTask(
          syncTask,
          syncTask,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(networkType: NetworkType.connected),
          // `update` keeps the existing 15-min cycle's timing instead of
          // resetting it on every app launch (`replace` pushed the first
          // run 15 min into the future each time the app opened).
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          backoffPolicy: BackoffPolicy.linear,
          backoffPolicyDelay: const Duration(minutes: 1),
        );

        // Kick off the 4-min chain. `replace` so a stale long-delayed
        // entry from a previous session doesn't push the first sync out.
        await scheduleNextChainSync(ExistingWorkPolicy.replace);
      } else {
        // iOS: submits the initial BGAppRefreshTaskRequest. The native
        // handler re-submits itself on every run (see workmanager_apple).
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

  /// (Re-)enqueues the next chain run. Safe to call from any isolate.
  ///
  /// Policy notes:
  ///  • the chain task itself re-schedules with `replace` so its own
  ///    retry copy can never coexist with the next link;
  ///  • the periodic watchdog re-schedules with `keep` so it only
  ///    repairs a broken chain and never postpones a pending link.
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
    log('Workmanager cancelled: $syncTask + $chainSyncTask',
        name: 'BackgroundStepsWorker');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (Platform.isAndroid && task == BackgroundStepsWorker.syncTask) {
        // Periodic watchdog: resurrect the FG service and make sure the
        // sync chain is alive. Deliberately does NOT run the sync — the
        // chain owns all storage access, so the two unique works can
        // never write concurrently.
        await _ensureFgServiceRunning();
        await BackgroundStepsWorker.scheduleNextChainSync(
          ExistingWorkPolicy.keep,
        );
        return true;
      }

      // Chain task (Android) or BGAppRefresh (iOS): full sync.
      await _runFullSync();
      return true;
    } catch (e, s) {
      log('BG task failed: $e',
          name: 'BackgroundStepsWorker', error: e, stackTrace: s);
      // Return true anyway: the chain (Android) / next BGAppRefresh (iOS)
      // is the retry mechanism. Letting WorkManager retry with backoff
      // would race the next chain link for no benefit.
      return true;
    } finally {
      if (Platform.isAndroid && task == BackgroundStepsWorker.chainSyncTask) {
        try {
          await BackgroundStepsWorker.scheduleNextChainSync(
            ExistingWorkPolicy.replace,
          );
        } catch (e) {
          log('Chain re-schedule failed: $e', name: 'BackgroundStepsWorker');
          // Non-fatal — the 15-min periodic watchdog restores the chain.
        }
      }
    }
  });
}

Future<void> _runFullSync() async {
  if (!GetIt.I.isRegistered<StepRepo>()) {
    await configureDependencies(isBackground: true);
  }

  final stepRepo = GetIt.I<StepRepo>();
  final db = StepLedgerDb.instance;
  final sync = StepSyncService(stepRepo);

  // ── 1. Merge every local source into the ledger (max-semantics) ─────

  if (Platform.isAndroid) {
    // Watchdog: nudge the native FG service back up if the OEM killed it.
    await _ensureFgServiceRunning();

    // Native FG service counters — today's running total AND the
    // finalized `hist_*` days, so a user who hasn't opened the app for
    // days still gets those days into the ledger from the background.
    await _hydrateFromNativePrefs(db);
  }

  // Health history for the past week — at most once per calendar day
  // (marker-gated), so a health-mode device that stays unopened still
  // feeds yesterday-and-back into the ledger. Late-settling tracker
  // data (e.g. Samsung Health syncing last night's walk this morning)
  // is picked up by the daily re-read and max-merged upward.
  await sync.hydrateHealthHistory(days: 7, oncePerDay: true);

  // Today's Health aggregate — cheap single read, every cycle. The HC
  // aggregate de-duplicates across source apps, so max(native, health)
  // can never double-count.
  final healthSteps = await _readTodayHealthSteps(stepRepo);
  if (healthSteps > 0) {
    await db.ensureDayAtLeast(
        StepLedgerDb.dayKey(DateTime.now()), healthSteps);
  }

  // Keep both tables bounded to the rolling 30-day window.
  await db.pruneOldLedgerDays();
  await db.pruneOldBackendSyncKeys();

  // ── 2. One pipeline: ledger → backend ───────────────────────────────
  // POSTs today plus every pending past day, advancing the shared
  // `step_days.synced` high-water mark per confirmed success. Nothing
  // is sent when nothing moved forward.
  await sync.syncPendingToBackend();
}

/// Today's step total from the central health repository, or 0.
Future<int> _readTodayHealthSteps(StepRepo stepRepo) async {
  try {
    if (!await stepRepo.isHealthDataAvailable()) return 0;

    if (Platform.isIOS) {
      // HealthKit hides read-permission status (Apple privacy model), so
      // probe the store directly — getHealthStepsForDay skips the
      // permission gate on iOS and coalesces a denied read to 0.
      return await stepRepo.getHealthStepsForDay(DateTime.now());
    }

    // Android: only read when permission is already granted — the
    // background isolate has no UI to prompt with.
    if (!await stepRepo.hasHealthPermission()) return 0;
    return await stepRepo.getTodayHealthSteps();
  } catch (e) {
    log('BG health read failed: $e', name: 'BackgroundStepsWorker');
    return 0;
  }
}

/// Reads the native StepsFgService's SharedPreferences file directly.
///
/// This isolate can't use the `ai.calora.app/steps_native_fgs`
/// MethodChannel (it's registered on MainActivity, and WorkManager runs
/// a separate headless engine), but the prefs XML lives in our own
/// sandbox at `<dataDir>/shared_prefs/calora_steps_native.xml`, so we
/// parse it straight off disk. Absolute totals only — never deltas.
/// Returns silently on any parse/IO failure — the ledger just keeps its
/// current values.
Future<void> _hydrateFromNativePrefs(StepLedgerDb db) async {
  try {
    final docs = await getApplicationDocumentsDirectory(); // <dataDir>/app_flutter
    final file =
        File('${docs.parent.path}/shared_prefs/calora_steps_native.xml');
    if (!await file.exists()) return;
    final xml = await file.readAsString();

    int intOf(String name) {
      final m = RegExp('<int name="$name" value="(-?\\d+)"').firstMatch(xml);
      return m == null ? 0 : (int.tryParse(m.group(1)!) ?? 0);
    }

    // Finalized past days: hist_<yyyymmdd> → final displayed total.
    final hist = <String, int>{};
    for (final m
        in RegExp(r'<int name="hist_(\d{8})" value="(\d+)"').allMatches(xml)) {
      final d = m.group(1)!;
      final v = int.tryParse(m.group(2)!) ?? 0;
      if (v <= 0) continue;
      hist['${d.substring(0, 4)}-${d.substring(4, 6)}-${d.substring(6, 8)}'] =
          v;
    }
    if (hist.isNotEmpty) await db.hydrateFromNativeHistory(hist);

    // Today's running total — only if the persisted day is actually today.
    final now = DateTime.now();
    final todayInt = now.year * 10000 + now.month * 100 + now.day;
    if (intOf('day_yyyymmdd') == todayInt) {
      final todaySteps = intOf('shown_steps');
      if (todaySteps > 0) {
        await db.ensureDayAtLeast(StepLedgerDb.dayKey(now), todaySteps);
      }
    }
  } catch (e) {
    log('Native prefs hydration failed: $e', name: 'BackgroundStepsWorker');
  }
}

/// Kicks the `StepsWatchdogReceiver`, which starts the FG service if
/// it isn't already running. Idempotent — the service's
/// `handleAutoRestart` just re-asserts foreground when it's alive.
///
/// We can't use the `ai.calora.app/steps_native_fgs` MethodChannel from
/// this isolate — MainActivity is where the channel is registered, and
/// the WM plugin runs on a separate headless Flutter engine. A same-app
/// broadcast reaches the receiver from any isolate in the process.
Future<void> _ensureFgServiceRunning() async {
  if (!Platform.isAndroid) return;
  try {
    await const AndroidIntent(
      action: 'ai.calora.app.steps.WATCHDOG_KICK',
      package: 'ai.calora.app',
    ).sendBroadcast();
  } catch (e) {
    log('Watchdog kick failed: $e', name: 'BackgroundStepsWorker');
    // Non-fatal — the next chain link retries. The BootReceiver and
    // midnight AlarmManager are the other resurrection paths.
  }
}
