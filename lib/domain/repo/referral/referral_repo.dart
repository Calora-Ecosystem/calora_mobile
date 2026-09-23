import 'package:calora/domain/model/referral/referral_info.dart';

abstract class ReferralRepo {
  Future<ReferralInfo> getMy();

  Future<List<ReferredFriend>> getInvited();

  Future<ApplyReferralResult> apply(String code);
}
