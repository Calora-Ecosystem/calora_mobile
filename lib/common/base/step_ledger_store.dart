import 'package:hive/hive.dart';

class StepLedgerStore {
  static const _ledgerBoxName = 'steps_ledger';
  static const _metaBoxName = 'steps_meta';

  static const _kLastSensorTotal = 'last_sensor_total';
  static const _kLastSensorDate = 'last_sensor_date';

  Box get _ledger => Hive.box(_ledgerBoxName);
  Box get _meta => Hive.box(_metaBoxName);

  String dayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int getLastSensorTotal() => (_meta.get(_kLastSensorTotal) as int?) ?? -1;
  Future<void> setLastSensorTotal(int v) => _meta.put(_kLastSensorTotal, v);

  String? getLastSensorDate() => _meta.get(_kLastSensorDate) as String?;
  Future<void> setLastSensorDate(String date) => _meta.put(_kLastSensorDate, date);

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

    await _writeDay(key, newTotal, newSynced);
  }

  Future<void> setSynced(String key, int synced) async {
    final day = _readDay(key);
    await _writeDay(key, day['total']!, synced);
  }

  Future<void> onSensorTotal(int currentTotal, DateTime now) async {
    final todayKey = dayKey(now);
    final lastDate = getLastSensorDate();
    final prev = getLastSensorTotal();

    if (lastDate != null && lastDate != todayKey) {
      final oldDay = _readDay(lastDate);
      final oldTotal = oldDay['total']!;
      final oldSynced = oldDay['synced']!;

      await setLastSensorTotal(currentTotal);
      await setLastSensorDate(todayKey);

      final today = _readDay(todayKey);
      final newTotal = today['total']! + currentTotal;
      await _writeDay(todayKey, newTotal, today['synced']!);
      return;
    }

    if (prev < 0) {
      await setLastSensorTotal(currentTotal);
      await setLastSensorDate(todayKey);
      return;
    }

    var delta = currentTotal - prev;
    if (delta < 0) {
      delta = currentTotal;
    }

    final day = _readDay(todayKey);
    final newTotal = day['total']! + delta;

    await _writeDay(todayKey, newTotal, day['synced']!);
    await setLastSensorTotal(currentTotal);
    await setLastSensorDate(todayKey);
  }

  List<String> getAllPendingDays() {
    final allKeys = _ledger.keys.cast<String>().toList();
    return allKeys.where(isPending).toList();
  }

  String _lastDailyResyncKey(String dayKey) => 'last_daily_resync_$dayKey';

  DateTime? getLastDailyResync(String dayKey) {
    final timestamp = _meta.get(_lastDailyResyncKey(dayKey)) as int?;
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> setLastDailyResync(String dayKey, DateTime time) =>
      _meta.put(_lastDailyResyncKey(dayKey), time.millisecondsSinceEpoch);
}
