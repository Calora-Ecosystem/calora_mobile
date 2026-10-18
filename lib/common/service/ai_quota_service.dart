import 'dart:async';

import 'package:calora/common/service/premium_service.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/calories/ai_quota.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AiQuotaService {
  AiQuotaService(this._repo, this._store, this._premium);

  final CaloriesRepo _repo;
  final CommonStore _store;
  final PremiumService _premium;

  Stream<AiQuota> watch() async* {
    yield await _store.aiQuota();
    yield* _store.aiQuota.watch();
  }

  Future<AiQuota> refresh() async {
    final AiQuota quota;
    try {
      quota = await _repo.getAiQuota();
    } catch (_) {
      return _store.aiQuota();
    }
    await _store.aiQuota.set(quota);
    if (quota.isPremium != await _store.isUserPremium()) {
      unawaited(_premium.sync());
    }
    return quota;
  }
}
