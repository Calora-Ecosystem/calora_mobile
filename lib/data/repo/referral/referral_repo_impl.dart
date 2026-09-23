import 'package:calora/data/api/referral_api.dart';
import 'package:calora/domain/model/referral/referral_info.dart';
import 'package:calora/domain/repo/referral/referral_repo.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: ReferralRepo)
class ReferralRepoImpl implements ReferralRepo {
  final ReferralApi _api;

  ReferralRepoImpl(this._api);

  @override
  Future<ReferralInfo> getMy() => _api.getMy();

  @override
  Future<List<ReferredFriend>> getInvited() => _api.getInvited();

  @override
  Future<ApplyReferralResult> apply(String code) => _api.apply(code.trim());
}
