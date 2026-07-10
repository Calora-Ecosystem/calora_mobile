import 'package:hive/hive.dart';

class StepLedgerStore {
  static const ledgerBoxName = 'steps_ledger';
  static const metaBoxName = 'steps_meta';

  Box get _ledger => Hive.box(ledgerBoxName);

  Box get _meta => Hive.box(metaBoxName);

  String dayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, int> _readDay(String key) {
    final raw = _ledger.get(key);
    if (raw is Map) {
      return {
        'total': (raw['total'] as int?) ?? 0,
        'synced': (raw['synced'] as int?) ?? 0,
      };
    }
    return {'total': 0, 'synced': 0};
  }

  Future<void> _writeDay(String key, int total, int synced) async {
    final safeTotal = total < 0 ? 0 : total;
    final safeSynced = synced < 0 ? 0 : (synced > safeTotal ? safeTotal : synced);
    await _ledger.put(key, {'total': safeTotal, 'synced': safeSynced});
  }

  int totalFor(String key) => _readDay(key)['total']!;

  int syncedFor(String key) => _readDay(key)['synced']!;

  bool isPending(String key) => totalFor(key) > syncedFor(key);

  Future<void> ensureDayAtLeast(String key, int minTotal, {int? minSynced}) async {
    final day = _readDay(key);
    final curTotal = day['total']!;
    final curSynced = day['synced']!;

    final newTotal = curTotal < minTotal ? minTotal : curTotal;
    final newSynced = minSynced == null
        ? curSynced
        : (curSynced < minSynced ? minSynced : curSynced);

    if (newTotal > curTotal || (minSynced != null && newSynced > curSynced)) {
      await _writeDay(key, newTotal, newSynced);
    }
  }

  Future<void> addSteps(String key, int steps) async {
    if (steps <= 0) return;
    final day = _readDay(key);
    final newTotal = day['total']! + steps;
    await _writeDay(key, newTotal, day['synced']!);
  }

  Future<void> setSynced(String key, int synced) async {
    final day = _readDay(key);
    await _writeDay(key, day['total']!, synced);
  }

  Future<void> deleteDay(String key) async {
    await _ledger.delete(key);
  }

  List<String> getAllPendingDays() {
    final allKeys = _ledger.keys.cast<String>().toList();
    allKeys.sort();
    return allKeys.where(isPending).toList();
  }

  /// Rolling 30-day view of daily step totals from the local ledger,
  /// oldest-first, one entry per calendar day. Days with no entry are
  /// included with 0 so the caller can chart a continuous window
  /// without stitching. Fast — O(30) prefs reads.
  List<MapEntry<DateTime, int>> getLast30Days({int days = 30}) {
    final out = <MapEntry<DateTime, int>>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key = dayKey(d);
      out.add(MapEntry(d, totalFor(key)));
    }
    return out;
  }

  /// Merge historical daily totals from the native FG service prefs into
  /// the ledger. Only ever advances a day's `total` upward — never
  /// downgrades a day that already has a higher value in the ledger
  /// (e.g. because a Health Connect read filled it in more accurately).
  /// The `synced` field is left untouched so [getAllPendingDays] will
  /// pick up newly-imported days for backend sync on the next tick.
  Future<void> hydrateFromNativeHistory(Map<String, int> nativeByIsoDate) async {
    if (nativeByIsoDate.isEmpty) return;
    for (final entry in nativeByIsoDate.entries) {
      if (entry.value <= 0) continue;
      await ensureDayAtLeast(entry.key, entry.value);
    }
  }

  /// Trim the ledger down to a rolling window. Prevents unbounded growth
  /// after long-running installs. Called from the periodic sync worker.
  Future<void> pruneOldLedgerDays({int keepDays = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    final cutoffKey = dayKey(cutoff);
    final toDelete = <String>[];
    for (final k in _ledger.keys) {
      if (k is! String) continue;
      // Lexicographic compare works because `dayKey` is zero-padded ISO.
      if (k.compareTo(cutoffKey) < 0) toDelete.add(k);
    }
    for (final k in toDelete) {
      await _ledger.delete(k);
    }
  }

  int getLastSensorTotal() => (_meta.get('last_sensor_total') as int?) ?? -1;

  Future<void> setLastSensorTotal(int v) => _meta.put('last_sensor_total', v);

  String getLastSensorDate() {
    final now = DateTime.now();
    final today = dayKey(now);
    return (_meta.get('last_sensor_date') as String?) ?? today;
  }

  Future<void> setLastSensorDate(String date) => _meta.put('last_sensor_date', date);

  static const _backendSyncPrefix = 'backend_sync_';

  int getLastSyncedBackendTotal(String key) => (_meta.get('$_backendSyncPrefix$key') as int?) ?? -1;

  Future<void> setLastSyncedBackendTotal(String key, int v) => _meta.put('$_backendSyncPrefix$key', v);

  /// Removes `backend_sync_<day>` high-water-mark entries older than
  /// [keepDays] so the meta box doesn't accumulate one int per day
  /// indefinitely. Safe to call often — it only touches matching keys.
  Future<void> pruneOldBackendSyncKeys({int keepDays = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    final toDelete = <String>[];
    for (final k in _meta.keys) {
      if (k is! String || !k.startsWith(_backendSyncPrefix)) continue;
      final day = DateTime.tryParse(k.substring(_backendSyncPrefix.length));
      if (day != null && day.isBefore(cutoff)) toDelete.add(k);
    }
    for (final k in toDelete) {
      await _meta.delete(k);
    }
  }

  // StepLedgerStore classi ichiga:

  bool isHealthHintShown() => (_meta.get('health_hint_shown') as bool?) ?? false;

  Future<void> setHealthHintShown() => _meta.put('health_hint_shown', true);

  bool isHealthHintDismissed() => (_meta.get('health_hint_dismissed') as bool?) ?? false;

  Future<void> setHealthHintDismissed() => _meta.put('health_hint_dismissed', true);

  bool didUserOpenHealthApp() => (_meta.get('user_opened_health_app') as bool?) ?? false;

  Future<void> setUserOpenedHealthApp(bool v) => _meta.put('user_opened_health_app', v);

  bool isBatteryHintShown() => (_meta.get('battery_hint_shown') as bool?) ?? false;

  Future<void> setBatteryHintShown() => _meta.put('battery_hint_shown', true);

  /// Whether a one-time coach-mark tour with the given [id] has already been
  /// completed/skipped. `id` distinguishes the dashboard walkthrough from the
  /// per-page button tours (e.g. `add_food`, `steps`).
  bool isTourShown(String id) => (_meta.get('tour_shown_$id') as bool?) ?? false;

  Future<void> setTourShown(String id) => _meta.put('tour_shown_$id', true);

  /// Convenience for the dashboard walkthrough (also read by the battery
  /// prompt to avoid stacking dialogs on top of the tour).
  bool isFeatureTourShown() => isTourShown('dashboard');
}
