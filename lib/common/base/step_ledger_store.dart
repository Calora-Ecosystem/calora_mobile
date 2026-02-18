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
    final newSynced = minSynced == null ? curSynced : (curSynced < minSynced ? minSynced : curSynced);

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

  int getLastSensorTotal() => (_meta.get('last_sensor_total') as int?) ?? -1;
  Future<void> setLastSensorTotal(int v) => _meta.put('last_sensor_total', v);

  String getLastSensorDate() {
    final now = DateTime.now();
    final today = dayKey(now);
    return (_meta.get('last_sensor_date') as String?) ?? today;
  }

  Future<void> setLastSensorDate(String date) => _meta.put('last_sensor_date', date);

  int getLastSyncedBackendTotal(String key) => (_meta.get('backend_sync_$key') as int?) ?? -1;
  Future<void> setLastSyncedBackendTotal(String key, int v) => _meta.put('backend_sync_$key', v);
}
