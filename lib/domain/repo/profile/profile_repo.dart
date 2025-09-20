import 'package:calora/domain/model/detail/detail_info.dart';
import 'package:calora/domain/model/norms/daily_norms_request.dart';
import 'package:calora/domain/model/profile/profile.dart';
import 'package:calora/domain/model/profile/profile_request.dart';

abstract class ProfileRepo {
  Future<void> logout();

  Future<ProfileRequest> getProfile();

  Future<DailyNormsRequest> getDailyNorms();

  Future<List<DetailInfo>> getProfileDetail();
}
