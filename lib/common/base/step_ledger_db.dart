import 'dart:developer';

import 'package:calora/common/base/step_ledger_store.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';

/// Isolate-safe persistent store for all step data that is shared
/// between the main isolate and the background WorkManager isolate.
///
/// Why SQLite (`sqflite`) and not Hive / shared_preferences:
///  • sqflite serializes every statement through a single native worker
///    per database file, so concurrent access from multiple isolates in
///    the same process is safe — unlike Hive, whose box file corrupts
///    under multi-isolate writes.
///  • Every mutation here is a single atomic SQL statement (UPSERT with
///    MAX, incremental UPDATE), so even interleaved read-modify-write
///    sequences from two isolates can never lose the higher value. A
///    key-value store can't express "set to max(current, x)" atomically;
///    SQLite can, which is what makes the max-merge semantics genuinely
///    race-free rather than just "usually fine".
///
/// Schema
/// ──────
///   step_days(day TEXT PK, total INT, synced INT)
///     One row per calendar day (`yyyy-MM-dd`). `total` only ever moves
///     up within a day; `synced` is the backend high-water mark and is
///     clamped to `total`.
///   step_meta(key TEXT PK, value TEXT)
///     Sensor baselines, per-day backend sync marks, migration flag.
///
/// UI flags (feature tours, hints) intentionally stay in the Hive
/// [StepLedgerStore]: they are read synchronously in widget builds and
/// are only ever touched by the main isolate, so they carry no
/// corruption risk.
class StepLedgerDb {
  StepLedgerDb._();

  static final StepLedgerDb instance = StepLedgerDb._();

  static const _dbFileName = 'step_ledger.db';

  static const _kHiveMigrated = 'hive_migrated_v1';
  static const _backendSyncPrefix = 'backend_sync_';
  static const _kLastSensorTotal = 'last_sensor_total';
  static const _kLastSensorDate = 'last_sensor_date';

  static const _upsertDaySql = '''
    INSERT INTO step_days(day, total, synced) VALUES(?, ?, ?)
    ON CONFLICT(day) DO UPDATE SET
      total  = MAX(step_days.total, excluded.total, excluded.synced),
      synced = MAX(step_days.synced, excluded.synced)
  ''';

  static const _upsertMetaSql = '''
    INSERT INTO step_meta(key, value) VALUES(?, ?)
    ON CONFLICT(key) DO UPDATE SET value = excluded.value
  ''';

  Future<Database>? _opening;

  Future<Database> get _db => _opening ??= _open();

  Future<Database> _open() async {
    final path = '${await getDatabasesPath()}/$_dbFileName';
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE step_days(
            day    TEXT PRIMARY KEY,
            total  INTEGER NOT NULL DEFAULT 0,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE step_meta(
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Canonical zero-padded ISO day key (`yyyy-MM-dd`). Zero-padding keeps
  /// lexicographic ordering identical to chronological ordering, which
  /// the pruning queries rely on.
  static String dayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ── Day totals ──────────────────────────────────────────────────────

  Future<int> totalFor(String day) async {
    final db = await _db;
    final rows = await db.query('step_days',
        columns: ['total'], where: 'day = ?', whereArgs: [day], limit: 1);
    if (rows.isEmpty) return 0;
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<int> syncedFor(String day) async {
    final db = await _db;
    final rows = await db.query('step_days',
        columns: ['synced'], where: 'day = ?', whereArgs: [day], limit: 1);
    if (rows.isEmpty) return 0;
    return (rows.first['synced'] as int?) ?? 0;
  }

  /// One round-trip read of both columns — use when a caller needs the
  /// pending check (`total > synced`) without two queries.
  Future<({int total, int synced})> dayFor(String day) async {
    final db = await _db;
    final rows = await db.query('step_days',
        where: 'day = ?', whereArgs: [day], limit: 1);
    if (rows.isEmpty) return (total: 0, synced: 0);
    return (
      total: (rows.first['total'] as int?) ?? 0,
      synced: (rows.first['synced'] as int?) ?? 0,
    );
  }

  /// Raise the day's `total` (and optionally `synced`) to at least the
  /// given values. Atomic max-merge — never lowers anything, safe to
  /// call concurrently from any number of isolates.
  Future<void> ensureDayAtLeast(String day, int minTotal,
      {int? minSynced}) async {
    final safeSynced = (minSynced ?? 0) < 0 ? 0 : (minSynced ?? 0);
    var safeTotal = minTotal < 0 ? 0 : minTotal;
    if (safeSynced > safeTotal) safeTotal = safeSynced;
    if (safeTotal == 0 && safeSynced == 0) return;
    final db = await _db;
    await db.rawInsert(_upsertDaySql, [day, safeTotal, safeSynced]);
  }

  /// Atomic increment — used only by the in-process pedometer path
  /// (primarily iOS), never by the background worker, which works in
  /// absolute totals exclusively.
  Future<void> addSteps(String day, int steps) async {
    if (steps <= 0) return;
    final db = await _db;
    await db.rawInsert('''
      INSERT INTO step_days(day, total, synced) VALUES(?, ?, 0)
      ON CONFLICT(day) DO UPDATE SET total = step_days.total + excluded.total
    ''', [day, steps]);
  }

  /// Advance the backend high-water mark. Monotonic (never lowers) and
  /// clamped to `total`, in one atomic statement.
  Future<void> setSynced(String day, int synced) async {
    if (synced < 0) return;
    final db = await _db;
    await db.rawUpdate(
      'UPDATE step_days SET synced = MIN(MAX(synced, ?), total) WHERE day = ?',
      [synced, day],
    );
  }

  Future<List<String>> getAllPendingDays() async {
    final db = await _db;
    final rows = await db.query('step_days',
        columns: ['day'], where: 'total > synced', orderBy: 'day ASC');
    return rows.map((r) => r['day']! as String).toList();
  }

  /// Pending days (`total > synced`) together with their totals, oldest
  /// first, in one query — the input for a backfill sync cycle. [limit]
  /// bounds the worst-case batch after very long offline stretches.
  Future<List<({String day, int total})>> getPendingDaysWithTotals(
      {int limit = 62}) async {
    final db = await _db;
    final rows = await db.query('step_days',
        columns: ['day', 'total'],
        where: 'total > synced AND total > 0',
        orderBy: 'day ASC',
        limit: limit);
    return [
      for (final r in rows)
        (day: r['day']! as String, total: (r['total'] as int?) ?? 0),
    ];
  }

  /// Rolling window of daily totals, oldest-first, one entry per calendar
  /// day with 0 filled in for days without a row.
  Future<List<MapEntry<DateTime, int>>> getLast30Days({int days = 30}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startKey = dayKey(today.subtract(Duration(days: days - 1)));

    final db = await _db;
    final rows = await db.query('step_days',
        columns: ['day', 'total'], where: 'day >= ?', whereArgs: [startKey]);
    final byDay = <String, int>{
      for (final r in rows) r['day']! as String: (r['total'] as int?) ?? 0,
    };

    final out = <MapEntry<DateTime, int>>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      out.add(MapEntry(d, byDay[dayKey(d)] ?? 0));
    }
    return out;
  }

  /// Merge historical daily totals from the native FG service into the
  /// ledger — max-merge only, never lowers a day. `synced` is left
  /// untouched so [getAllPendingDays] picks newly-imported days up for
  /// backend sync.
  Future<void> hydrateFromNativeHistory(
      Map<String, int> nativeByIsoDate) async {
    if (nativeByIsoDate.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    for (final entry in nativeByIsoDate.entries) {
      if (entry.value <= 0) continue;
      batch.rawInsert(_upsertDaySql, [entry.key, entry.value, 0]);
    }
    await batch.commit(noResult: true);
  }

  /// Trim to a rolling window so the table never grows unbounded.
  /// Lexicographic compare is chronological thanks to zero-padded keys.
  Future<void> pruneOldLedgerDays({int keepDays = 30}) async {
    final cutoffKey =
        dayKey(DateTime.now().subtract(Duration(days: keepDays)));
    final db = await _db;
    await db.delete('step_days', where: 'day < ?', whereArgs: [cutoffKey]);
  }

  // ── Meta: sensor baselines & backend sync marks ─────────────────────

  Future<String?> _getMeta(String key) async {
    final db = await _db;
    final rows = await db.query('step_meta',
        columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _setMeta(String key, String value) async {
    final db = await _db;
    await db.rawInsert(_upsertMetaSql, [key, value]);
  }

  Future<int> getLastSensorTotal() async =>
      int.tryParse(await _getMeta(_kLastSensorTotal) ?? '') ?? -1;

  Future<void> setLastSensorTotal(int v) =>
      _setMeta(_kLastSensorTotal, '$v');

  Future<String> getLastSensorDate() async =>
      await _getMeta(_kLastSensorDate) ?? dayKey(DateTime.now());

  Future<void> setLastSensorDate(String date) =>
      _setMeta(_kLastSensorDate, date);

  static const _kHealthHistDay = 'health_hist_hydrated_day';

  /// Day key of the last completed Health history hydration — lets the
  /// 4-min background chain limit the (comparatively expensive) per-day
  /// Health reads to once per calendar day.
  Future<String?> getHealthHistoryHydratedDay() => _getMeta(_kHealthHistDay);

  Future<void> setHealthHistoryHydratedDay(String day) =>
      _setMeta(_kHealthHistDay, day);

  /// Removes legacy `backend_sync_<day>` marks (the pre-unification
  /// foreground high-water tracker — `step_days.synced` is the single
  /// tracker now) plus any that somehow survive beyond the window.
  Future<void> pruneOldBackendSyncKeys({int keepDays = 30}) async {
    final cutoffKey =
        dayKey(DateTime.now().subtract(Duration(days: keepDays)));
    final db = await _db;
    await db.delete(
      'step_meta',
      where: 'key LIKE ? AND key < ?',
      whereArgs: ['$_backendSyncPrefix%', '$_backendSyncPrefix$cutoffKey'],
    );
  }

  // ── One-time Hive → SQLite migration ────────────────────────────────

  /// Copies the old Hive ledger into SQLite. Call once at startup from
  /// the MAIN isolate (the only place the Hive boxes are open). The
  /// background isolate never opens Hive, so if it happens to create the
  /// database first the migration simply runs on the next app launch —
  /// all imports are max-merges, so order doesn't matter.
  ///
  /// Today's Hive entry is deliberately NOT migrated: ledgers written by
  /// builds before the delta-accumulation fix can carry a 2–3× inflated
  /// total for the in-progress day, and importing it would re-seed the
  /// native notification with the inflated number. Today is rebuilt
  /// cleanly from the native counter + Health within seconds of startup;
  /// finalized past days are kept for chart continuity.
  Future<void> migrateFromHiveIfNeeded() async {
    try {
      if (await _getMeta(_kHiveMigrated) == '1') return;
      if (!Hive.isBoxOpen(StepLedgerStore.ledgerBoxName) ||
          !Hive.isBoxOpen(StepLedgerStore.metaBoxName)) {
        return;
      }

      final ledger = Hive.box(StepLedgerStore.ledgerBoxName);
      final meta = Hive.box(StepLedgerStore.metaBoxName);
      final todayKey = dayKey(DateTime.now());

      final db = await _db;
      final batch = db.batch();

      var migratedDays = 0;
      for (final k in ledger.keys) {
        if (k is! String || k == todayKey) continue;
        final raw = ledger.get(k);
        if (raw is! Map) continue;
        final total = (raw['total'] as int?) ?? 0;
        if (total <= 0) continue;
        var synced = (raw['synced'] as int?) ?? 0;
        if (synced < 0) synced = 0;
        if (synced > total) synced = total;
        batch.rawInsert(_upsertDaySql, [k, total, synced]);
        migratedDays++;
      }

      // Sensor baselines — preserved so the in-process pedometer path
      // keeps its mid-day baseline across the storage swap instead of
      // dropping the steps between the last event and the update.
      final lastTotal = meta.get(_kLastSensorTotal);
      if (lastTotal is int) {
        batch.rawInsert(_upsertMetaSql, [_kLastSensorTotal, '$lastTotal']);
      }
      final lastDate = meta.get(_kLastSensorDate);
      if (lastDate is String) {
        batch.rawInsert(_upsertMetaSql, [_kLastSensorDate, lastDate]);
      }

      // Backend high-water marks — keep the monotonic POST guard intact.
      for (final k in meta.keys) {
        if (k is! String || !k.startsWith(_backendSyncPrefix)) continue;
        final v = meta.get(k);
        if (v is int) batch.rawInsert(_upsertMetaSql, [k, '$v']);
      }

      batch.rawInsert(_upsertMetaSql, [_kHiveMigrated, '1']);
      await batch.commit(noResult: true);
      log('Hive → SQLite migration complete ($migratedDays day(s))',
          name: 'StepLedgerDb');
    } catch (e, s) {
      // Flag not written — migration retries on the next launch.
      log('Hive migration failed (will retry next launch): $e',
          name: 'StepLedgerDb', stackTrace: s);
    }
  }
}
