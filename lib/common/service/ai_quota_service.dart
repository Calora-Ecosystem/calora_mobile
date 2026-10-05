import 'package:calora/common/di/network/interceptor/token_interceptor.dart';
import 'package:calora/data/store/common/common_store.dart';
import 'package:calora/domain/model/calories/ai_quota.dart';
import 'package:calora/domain/repo/calories/calories_repo.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AiQuotaService {
  AiQuotaService(this._repo, this._store, this._tokens);

  final CaloriesRepo _repo;
  final CommonStore _store;
  final TokenInterceptor _tokens;

  bool _premiumSyncAttempted = false;

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
    await _syncPremium(quota);
    return quota;
  }

  Future<void> _syncPremium(AiQuota quota) async {
    if (!quota.isPremium || _premiumSyncAttempted) return;
    if (await _store.isUserPremium()) return;
    _premiumSyncAttempted = true;
    await _tokens.refreshAndCheckPremium();
  }
}
