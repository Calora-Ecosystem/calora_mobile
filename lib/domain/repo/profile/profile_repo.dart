import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/norms/norms.dart';
import 'package:calora/domain/model/profile/profile_request.dart';

abstract class ProfileRepo {
  Future<ProfileRequest> getProfile();
  Future<void> updateProfile(ProfileRequest request);

  Future<List<DetailInfo>> getDailyNorms();

  Future<List<DetailInfo>> getProfileDetail();
  Future<void> updateSingleNorm(NormsRequest request);
  Future<void> logOut();

  Future<void> deleteAccount(String userId);
}
