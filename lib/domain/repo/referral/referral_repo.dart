import 'package:calora/domain/model/referral/referral_info.dart';

abstract class ReferralRepo {
  Future<ReferralInfo> getMy();

  /// A fresh invite code for this share — every earlier code keeps working.
  Future<String> newCode();

  Future<List<ReferredFriend>> getInvited();

  Future<ApplyReferralResult> apply(String code);
}
