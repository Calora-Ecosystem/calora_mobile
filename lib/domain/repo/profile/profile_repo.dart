import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/norms/daily_norms_info.dart';
import 'package:calora/domain/model/profile/profile_request.dart';

abstract class ProfileRepo {
  Future<void> logout();

  Future<ProfileRequest> getProfile();

  Future<List<DetailInfo>> getDailyNorms();

  Future<List<DetailInfo>> getProfileDetail();
  Future<void> updateDailyNorms(DailyNormsInfo dailyNormsInfo);
}
