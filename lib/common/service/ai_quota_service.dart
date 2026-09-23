import 'dart:math';

import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/calories/ai_quota.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';

/// Free AI recognition allowance. The backend enforces and counts it (only a
/// successful recognition is counted); this service reads it and mirrors it
/// into [CommonStore] so the add-food banner updates reactively.
@lazySingleton
class AiQuotaService {
  final CaloriesRepo _repo;
  final CommonStore _store;

  AiQuotaService(this._repo, this._store);

  /// Fetches the quota from the server. Offline, falls back to the last
  /// cached values so the UI still shows something sensible.
  Future<AiQuota> refresh() async {
    try {
      final quota = await _repo.getAiQuota();
      await _store.freeAiScansUsed.set(quota.used);
      await _store.freeAiScanLimit.set(quota.limit);
      return quota;
    } catch (_) {
      final used = await _store.freeAiScansUsed();
      final limit = await _store.freeAiScanLimit();
      return AiQuota(limit: limit, used: used, remaining: max(0, limit - used));
    }
  }
}
