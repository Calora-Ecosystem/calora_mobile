import 'package:hive/hive.dart';

/// MAIN-ISOLATE-ONLY UI flags (feature tours, one-time hints).
///
/// All step DATA (day totals, sync marks, sensor baselines) lives in
/// `StepLedgerDb` (SQLite), which is safe to touch from the background
/// WorkManager isolate. This Hive store must never be opened or written
/// from a background isolate — Hive is not multi-isolate-safe, and
/// keeping it single-isolate is exactly what makes it safe to keep for
/// the synchronous flag reads the widget layer needs.
///
/// The `steps_ledger` box is retained (and still opened in main.dart)
/// only so `StepLedgerDb.migrateFromHiveIfNeeded()` can import legacy
/// data; once every install has migrated it can be dropped.
class StepLedgerStore {
  static const ledgerBoxName = 'steps_ledger';
  static const metaBoxName = 'steps_meta';

  Box get _meta => Hive.box(metaBoxName);

  bool isHealthHintShown() => (_meta.get('health_hint_shown') as bool?) ?? false;

  Future<void> setHealthHintShown() => _meta.put('health_hint_shown', true);

  bool isHealthHintDismissed() => (_meta.get('health_hint_dismissed') as bool?) ?? false;

  Future<void> setHealthHintDismissed() => _meta.put('health_hint_dismissed', true);

  bool didUserOpenHealthApp() => (_meta.get('user_opened_health_app') as bool?) ?? false;

  Future<void> setUserOpenedHealthApp(bool v) => _meta.put('user_opened_health_app', v);

  bool isBatteryHintShown() => (_meta.get('battery_hint_shown') as bool?) ?? false;

  Future<void> setBatteryHintShown() => _meta.put('battery_hint_shown', true);

  /// Whether the one-time Health Connect background-read permission
  /// prompt has already been shown, so we never nag the user with the
  /// system dialog on every health-mode activation.
  bool isBgReadPromptShown() => (_meta.get('bg_read_prompt_shown') as bool?) ?? false;

  Future<void> setBgReadPromptShown() => _meta.put('bg_read_prompt_shown', true);

  /// Whether a one-time coach-mark tour with the given [id] has already been
  /// completed/skipped. `id` distinguishes the dashboard walkthrough from the
  /// per-page button tours (e.g. `add_food`, `steps`).
  bool isTourShown(String id) => (_meta.get('tour_shown_$id') as bool?) ?? false;

  Future<void> setTourShown(String id) => _meta.put('tour_shown_$id', true);

  /// Convenience for the first-run walkthrough (also read by the battery
  /// prompt to avoid stacking dialogs on top of the tour). The Home tab is the
  /// first tour a user sees, so its completion marks the walkthrough as begun.
  bool isFeatureTourShown() => isTourShown('tour_home');
}
